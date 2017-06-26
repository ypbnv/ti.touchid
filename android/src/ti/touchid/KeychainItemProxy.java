/**
 * Axway Appcelerator Titanium - ti.touchid
 * Copyright (c) 2017 by Axway. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.touchid;

import org.appcelerator.kroll.KrollFunction;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.titanium.TiApplication;

import android.content.Context;
import android.security.KeyPairGeneratorSpec;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.math.BigInteger;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.util.Calendar;
import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import javax.security.auth.x500.X500Principal;

@Kroll.proxy(creatableInModule=TouchidModule.class)
public class KeychainItemProxy extends KrollProxy {

	private static final String TAG = "KeychainItem";

	public static final String PROPERTY_IDENTIFIER = "identifier";
	public static final String EVENT_SAVE = "save";
	public static final String EVENT_READ = "read";
	public static final String EVENT_UPDATE = "update";
	public static final String EVENT_RESET = "reset";

	private KeyStore keyStore;
	private KeyPair keyPair;
	private String algorithm = "RSA/ECB/PKCS1Padding";
	private String identifier = "";
	private String suffix = "_kc.dat";
	private Context context = null;

	public KeychainItemProxy() {
		super();

		try {
			context = TiApplication.getAppRootOrCurrentActivity();

			// load Android key store
			keyStore = KeyStore.getInstance("AndroidKeyStore");
			keyStore.load(null);
		} catch (Exception e) {
			Log.e(TAG, "could not load Android key store: " + e.getMessage());
		}
	}

	private KrollDict writeValue(String value) {
		KrollDict result = new KrollDict();
		result.put("identifier", identifier);
		try {
			// create encryption cipher
			Cipher cipher = Cipher.getInstance(algorithm);
			cipher.init(Cipher.ENCRYPT_MODE, keyPair.getPrivate());

			// save encrypted data to private storage
			FileOutputStream fos = context.openFileOutput(identifier + suffix, Context.MODE_PRIVATE);
			CipherOutputStream cos = new CipherOutputStream(new BufferedOutputStream(fos), cipher);
			cos.write(value.getBytes());
			cos.close();

			result.put("success", true);
			result.put("code", 0);
		} catch (Exception e) {
			result.put("success", false);
			result.put("code", -1);
			result.put("error", e.getMessage());
		}
		return result;
	}

	private KrollDict readValue() {
		KrollDict result = new KrollDict();
		result.put("identifier", identifier);
		try {
			// create decryption cipher
			Cipher cipher = Cipher.getInstance(algorithm);
			cipher.init(Cipher.DECRYPT_MODE, keyPair.getPublic());

			// load file from private storage
			FileInputStream fin = context.openFileInput(identifier + suffix);
			CipherInputStream cis = new CipherInputStream(new BufferedInputStream(fin), cipher);

			// read and decrypt file
			byte[] buffer = new byte[1024];
			int length = 0;
			int total = 0;
			String decrypted = "";
			while ((length = cis.read(buffer)) != -1) {
				// since we only encrypt strings, this is acceptable
				decrypted += new String(buffer, "UTF-8");
				total += length;
			}
			decrypted = decrypted.substring(0, total);

			result.put("success", true);
			result.put("code", 0);
			result.put("value", decrypted);
		} catch (Exception e) {
			result.put("success", false);
			result.put("code", -1);
			if (e instanceof FileNotFoundException) {
				result.put("error", "keychain data does not exist!");
			} else {
				result.put("error", e.getMessage());
			}
		}
		return result;
	}

	@Kroll.method
	public void save(String value) {
		fireEvent(EVENT_SAVE, writeValue(value));
	}

	@Kroll.method
	public void read() {
		fireEvent(EVENT_READ, readValue());
	}

	@Kroll.method
	public void update(String value) {
		fireEvent(EVENT_UPDATE, writeValue(value));
	}

	@Kroll.method
	public void reset() {
		KrollDict result = new KrollDict();
		boolean deleted = false;

		// delete file from private storage
		File file = new File(identifier + suffix);
		if (file != null) {
			deleted = context.deleteFile(identifier + suffix);

			// remove key from Android key store
			if (deleted) {
				try {
					keyStore.deleteEntry(identifier);
				} catch (Exception e) {
					Log.d(TAG, "could not remove key");
				}
			}
		}

		result.put("success", deleted);
		result.put("code", deleted ? 0 : -1);
		fireEvent(EVENT_RESET, result);
	}

	@Kroll.method
	public void fetchExistence(Object callback) {
		if (callback instanceof KrollFunction) {
			KrollDict result = new KrollDict();
			result.put("exists", new File(identifier + suffix) != null);
			((KrollFunction) callback).callAsync(krollObject, new Object[]{result});
		}
	}

	@Override
	public void handleCreationDict(KrollDict dict) {
		super.handleCreationDict(dict);

		if (dict.containsKey(PROPERTY_IDENTIFIER)) {
			identifier = dict.getString(PROPERTY_IDENTIFIER);
			if (!identifier.isEmpty()) {
				try {
					if (!keyStore.containsAlias(identifier)) {
						Calendar startDate = Calendar.getInstance();
						Calendar endDate = Calendar.getInstance();
						endDate.add(Calendar.YEAR, 1);
						KeyPairGeneratorSpec spec = new KeyPairGeneratorSpec.Builder(context)
								.setAlias(identifier)
								.setKeyType("RSA")
								.setKeySize(2048)
								.setSubject(new X500Principal("CN=titouchid"))
								.setSerialNumber(BigInteger.ONE)
								.setStartDate(startDate.getTime())
								.setEndDate(endDate.getTime())
								.build();
						KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA", "AndroidKeyStore");
						generator.initialize(spec);
						keyPair = generator.generateKeyPair();
					} else {
						KeyStore.PrivateKeyEntry keys = (KeyStore.PrivateKeyEntry) keyStore.getEntry(identifier, null);
						keyPair = new KeyPair(keys.getCertificate().getPublicKey(), keys.getPrivateKey());
					}
				} catch (Exception e) {
					Log.e(TAG, e.toString());
				}
			}
		}
	}

	@Override
	public String getApiName() {
		return "ti.touchid.KeychainItem";
	}
}
