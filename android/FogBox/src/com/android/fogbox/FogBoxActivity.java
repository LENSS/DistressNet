package com.android.fogbox;


import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

public class FogBoxActivity extends Activity {
    /** Called when the activity is first created. */
	private Button mOkButton;
	private Button mCancelButton;
	private EditText mEditText1;
	private EditText mEditText2;
	public static final String username = "";
	public static final String password = "";
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
     
    }
    public void onResume(){
    	super.onResume();
    	 mOkButton = (Button) findViewById(R.id.buttonOk);
    	 mCancelButton = (Button) findViewById(R.id.buttonCancel);
    	 mEditText1 = (EditText)findViewById(R.id.editText1);
    	 mEditText2 = (EditText)findViewById(R.id.editText2);
    	 mEditText1.setText("");
    	 mEditText2.setText("");
    	 mOkButton.setOnClickListener(new OnClickListener() {
             public void onClick(View v) {
                 // Send a message using content of the edit text widget
            	 //String newString = mEditText1.getText().toString();
            	 //String newString1 = mEditText2.getText().toString();
            	 if((mEditText1.getText().toString().equals(FogBoxActivity.username)) && (mEditText2.getText().toString().equals(FogBoxActivity.password)))
            	 //if(true)
            	 {	 
            		 Intent filelistIntent = new Intent(FogBoxActivity.this, FileList.class);
            		 startActivity(filelistIntent);
            	 }
            	 else
            	 {
            		 Toast.makeText(FogBoxActivity.this,R.string.IncorrectLogin, Toast.LENGTH_SHORT).show();
            		 
            	 }
              
             }
         });
    	 mCancelButton.setOnClickListener(new OnClickListener() {
             public void onClick(View v) {
            	 Toast.makeText(FogBoxActivity.this,R.string.Exiting, Toast.LENGTH_SHORT).show();
                 finish();
                 return;
             }
         });
    }
}