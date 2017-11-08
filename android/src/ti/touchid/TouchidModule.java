/**
 * Axway Appcelerator Titanium - ti.touchid
 * Copyright (c) 2017 by Axway. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.touchid;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollFunction;

import java.lang.Override;
import java.util.HashMap;

import android.app.Activity;
import android.hardware.fingerprint.FingerprintManager;
import android.os.Build;

@Kroll.module(name="Touchid", id="ti.touchid")
public class TouchidModule extends KrollModule
{
	private static final String TAG = "Touchid";
	public static final int PERMISSION_CODE_FINGERPRINT = 99;

	@Kroll.constant public static final int SUCCESS = 0;
	@Kroll.constant public static final int SERVICE_MISSING = 1;
	@Kroll.constant public static final int SERVICE_VERSION_UPDATE_REQUIRED = 2;
	@Kroll.constant public static final int SERVICE_DISABLED = 3;
	@Kroll.constant public static final int SERVICE_INVALID = 9;

	@Kroll.constant public static final int ACCESSIBLE_ALWAYS = KeychainItemProxy.ACCESSIBLE_ALWAYS;
	@Kroll.constant public static final int ACCESSIBLE_ALWAYS_THIS_DEVICE_ONLY = KeychainItemProxy.ACCESSIBLE_ALWAYS_THIS_DEVICE_ONLY;
	@Kroll.constant public static final int ACCESSIBLE_WHEN_PASSCODE_SET_THIS_DEVICE_ONLY = KeychainItemProxy.ACCESSIBLE_WHEN_PASSCODE_SET_THIS_DEVICE_ONLY;

	@Kroll.constant public static final int ACCESS_CONTROL_USER_PRESENCE = KeychainItemProxy.ACCESS_CONTROL_USER_PRESENCE;
	@Kroll.constant public static final int ACCESS_CONTROL_DEVICE_PASSCODE = KeychainItemProxy.ACCESS_CONTROL_DEVICE_PASSCODE;
	@Kroll.constant public static final int ACCESS_CONTROL_TOUCH_ID_ANY = KeychainItemProxy.ACCESS_CONTROL_TOUCH_ID_ANY;
	@Kroll.constant public static final int ACCESS_CONTROL_TOUCH_ID_CURRENT_SET = KeychainItemProxy.ACCESS_CONTROL_TOUCH_ID_CURRENT_SET;

	@Kroll.constant public static final int ERROR_TOUCH_ID_LOCKOUT = FingerprintManager.FINGERPRINT_ERROR_LOCKOUT;
	@Kroll.constant public static final int ERROR_AUTHENTICATION_FAILED = -1;
	@Kroll.constant public static final int ERROR_TOUCH_ID_NOT_ENROLLED = -2;
	@Kroll.constant public static final int ERROR_TOUCH_ID_NOT_AVAILABLE = -3;
	@Kroll.constant public static final int ERROR_PASSCODE_NOT_SET = -4;
	@Kroll.constant public static final int ERROR_KEY_PERMANENTLY_INVALIDATED = -5;

	@Kroll.constant public static final int FINGERPRINT_ACQUIRED_PARTIAL = FingerprintManager.FINGERPRINT_ACQUIRED_PARTIAL;
	@Kroll.constant public static final int FINGERPRINT_ACQUIRED_INSUFFICIENT = FingerprintManager.FINGERPRINT_ACQUIRED_INSUFFICIENT;
	@Kroll.constant public static final int FINGERPRINT_ACQUIRED_IMAGER_DIRTY = FingerprintManager.FINGERPRINT_ACQUIRED_IMAGER_DIRTY;
	@Kroll.constant public static final int FINGERPRINT_ACQUIRED_TOO_SLOW = FingerprintManager.FINGERPRINT_ACQUIRED_TOO_SLOW;
	@Kroll.constant public static final int FINGERPRINT_ACQUIRED_TOO_FAST = FingerprintManager.FINGERPRINT_ACQUIRED_TOO_FAST;

	protected FingerPrintHelper mfingerprintHelper;
	private Throwable fingerprintHelperException;

	public TouchidModule() {
		super();
		init();
	}

	private void init() {
		if (Build.VERSION.SDK_INT >= 23) {
			try {
				mfingerprintHelper = new FingerPrintHelper();
			} catch (Exception e) {
				mfingerprintHelper = null;
				fingerprintHelperException = e.getCause();
				Log.e(TAG, fingerprintHelperException.getMessage());
			}
		}
	}

	@Kroll.method
	public void authenticate(HashMap params) {
		if (mfingerprintHelper == null) {
			init();
		}
		if (params == null || mfingerprintHelper == null) {
			return;
		}
		if (params.containsKey("callback")) {
			Object callback = params.get("callback");
			if (callback instanceof KrollFunction) {
				mfingerprintHelper.startListening((KrollFunction)callback, getKrollObject());
			}
		}
	}

	@Kroll.method
	public HashMap deviceCanAuthenticate() {
		if (mfingerprintHelper == null) {
			init();
		}
		if (Build.VERSION.SDK_INT >= 23 && mfingerprintHelper != null) {
			return mfingerprintHelper.deviceCanAuthenticate();
		}

		KrollDict response = new KrollDict();
		response.put("canAuthenticate", false);
		response.put("code", TouchidModule.ERROR_TOUCH_ID_NOT_AVAILABLE);
		if (Build.VERSION.SDK_INT < 23) {
			response.put("error", "Device is running with API < 23");
		} else if (fingerprintHelperException != null) {
			response.put("error", fingerprintHelperException.getMessage());
		} else {
			response.put("error", "Device does not support fingerprint authentication");
		}

		return response;
	}

	@Kroll.method
	public boolean isSupported() {
		if (mfingerprintHelper == null) {
			init();
		}
		if (Build.VERSION.SDK_INT >= 23 && mfingerprintHelper != null) {
			return mfingerprintHelper.isDeviceSupported();
		}
		return false;
	}
	
	@Override
	public void onPause(Activity activity) {
		super.onPause(activity);	
		if (mfingerprintHelper != null) {
			mfingerprintHelper.stopListening();
		}	
	}

	@Kroll.method
	public void invalidate() {
		if (mfingerprintHelper != null) {
			mfingerprintHelper.stopListening();
		}
	}
}
