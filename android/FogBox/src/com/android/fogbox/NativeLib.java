package com.android.fogbox;

import android.content.res.AssetManager;

public class NativeLib {
	static {
	    System.loadLibrary("tftpc");
	  }
	  
	  /** 
	   * Sends a file
	   */
	public native void setAppName(String sourceDir);
	public native void sendFile(String serverIP,String portNo,String FilePath, String Filename);
	public native void closezip();
	public void appupdate(int count)
	{
		FileShareActivity fileshareclass = new FileShareActivity();
		fileshareclass.appupdate(count);
	}

		  

}
