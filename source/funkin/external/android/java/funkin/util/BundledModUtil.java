package funkin.util;

import android.content.res.AssetManager;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

import org.haxe.extension.Extension;

/**
 * Extracts the mods bundled inside the APK (under `assets/bundled_mods/`) into the game's
 * external files directory, so Polymod can read them like any other installed mod.
 *
 * The bundle carries a `manifest.txt` whose first line is a version stamp and every
 * following line is `<size>\t<relative path>`. Extraction is skipped when the stamp
 * already on disk matches, and runs on a background thread so the preloader can show progress.
 */
public class BundledModUtil
{
	private static final String TAG = "BundledModUtil";
	private static final String BUNDLE_DIR = "bundled_mods";
	private static final String STAMP_FILE = ".bundled_mods_version";

	private static volatile long copiedBytes = 0;
	private static volatile long totalBytes = 0;
	// 0 = idle, 1 = running, 2 = done, 3 = failed
	private static volatile int state = 0;
	private static volatile String error = "";

	public static boolean needsExtraction()
	{
		try
		{
			String stamp = readStamp();
			if (stamp == null) return false;

			File stampFile = new File(Extension.mainContext.getExternalFilesDir(null), STAMP_FILE);
			if (!stampFile.exists()) return true;

			BufferedReader reader = new BufferedReader(new InputStreamReader(new java.io.FileInputStream(stampFile), "UTF-8"));
			String current = reader.readLine();
			reader.close();
			return !stamp.equals(current);
		}
		catch (Exception e)
		{
			Log.e(TAG, "needsExtraction failed", e);
			return true;
		}
	}

	public static void startExtraction()
	{
		if (state == 1) return;

		state = 1;
		copiedBytes = 0;
		totalBytes = 0;
		error = "";

		new Thread(new Runnable()
		{
			@Override
			public void run()
			{
				try
				{
					extract();
					state = 2;
				}
				catch (Throwable e)
				{
					Log.e(TAG, "Extraction failed", e);
					error = e.toString();
					state = 3;
				}
			}
		}, "BundledModExtractor").start();
	}

	public static int getState()
	{
		return state;
	}

	public static float getProgress()
	{
		long total = totalBytes;
		if (total <= 0) return 0;
		return (float) ((double) copiedBytes / (double) total);
	}

	public static String getError()
	{
		return error;
	}

	private static String readStamp() throws Exception
	{
		AssetManager assets = Extension.mainContext.getAssets();
		InputStream in;
		try
		{
			in = assets.open(BUNDLE_DIR + "/manifest.txt");
		}
		catch (Exception e)
		{
			return null;
		}
		BufferedReader reader = new BufferedReader(new InputStreamReader(in, "UTF-8"));
		String stamp = reader.readLine();
		reader.close();
		return stamp;
	}

	private static void extract() throws Exception
	{
		AssetManager assets = Extension.mainContext.getAssets();
		File root = Extension.mainContext.getExternalFilesDir(null);
		File modsDir = new File(root, "mods");

		BufferedReader reader = new BufferedReader(new InputStreamReader(assets.open(BUNDLE_DIR + "/manifest.txt"), "UTF-8"));
		String stamp = reader.readLine();
		List<String> paths = new ArrayList<String>();
		long total = 0;
		String line;
		while ((line = reader.readLine()) != null)
		{
			int tab = line.indexOf('\t');
			if (tab <= 0) continue;
			total += Long.parseLong(line.substring(0, tab));
			paths.add(line.substring(tab + 1));
		}
		reader.close();
		totalBytes = total;

		// Remove the previously extracted copies of the bundled mods so stale files don't linger.
		java.util.Set<String> modFolders = new java.util.HashSet<String>();
		for (String path : paths)
		{
			int slash = path.indexOf('/');
			if (slash > 0) modFolders.add(path.substring(0, slash));
		}
		for (String folder : modFolders)
			deleteRecursive(new File(modsDir, folder));

		byte[] buffer = new byte[1 << 16];
		for (String path : paths)
		{
			File out = new File(modsDir, path);
			File parent = out.getParentFile();
			if (parent != null && !parent.exists()) parent.mkdirs();

			InputStream in = assets.open(BUNDLE_DIR + "/" + path, AssetManager.ACCESS_STREAMING);
			OutputStream os = new FileOutputStream(out);
			int read;
			while ((read = in.read(buffer)) != -1)
			{
				os.write(buffer, 0, read);
				copiedBytes += read;
			}
			os.close();
			in.close();
		}

		FileOutputStream stampOut = new FileOutputStream(new File(root, STAMP_FILE));
		stampOut.write(stamp.getBytes("UTF-8"));
		stampOut.close();
	}

	private static void deleteRecursive(File file)
	{
		File[] children = file.listFiles();
		if (children != null)
		{
			for (File child : children)
				deleteRecursive(child);
		}
		file.delete();
	}
}
