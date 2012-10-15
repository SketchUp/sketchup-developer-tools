// Copyright 2012 Trimble Navigation Ltd.
// Apache License, version 2.0

/**
 * @fileoverview 
 * @author Matt Lowrie
 * @version 0.1
 */
 
/**
 * Script utilities
 */
var sh = new ActiveXObject('WScript.Shell');
var fso = new ActiveXObject('Scripting.FileSystemObject');

/**
 * Variables
 */
var rubyItemsToCopy = {
                        'optparse.rb' : 'file',
                        'testuprunner.rb' : 'file',
                        'test' : 'dir'
};

var targetPath = null;
if ( WScript.Arguments.Named.Exists('path') ) {
  targetPath = WScript.Arguments.Named.Item('path');
}

// Should always be a target directory, so if not just quit
var targetDir = null;
if ( targetPath != null )
  targetDir = targetPath.split('\SketchUp.exe')[0];
else
  WScript.Quit(1);
var pluginsDir = targetDir + '\\Plugins\\';

/**
 * Copies the required files to the target plugins directory.
 */
function MoveItems(shouldCopy){
  // This script is executed from the master HTA, so its directory 
  // is the current directory and everything is relative to it.
  var srcDir = pluginsDir;
  if ( shouldCopy )
    srcDir = 'ruby\\';

  for ( var item in rubyItemsToCopy ) {
    var f = null;
    if ( rubyItemsToCopy[item] == 'file' )
      f = fso.GetFile(srcDir + item);
    else if ( rubyItemsToCopy[item] == 'dir' )
      f = fso.GetFolder(srcDir + item);

    if ( shouldCopy ) {
      // Check if the file is already in the destination, 
      // possibly from an aborted test run
      if ( fso.FileExists(pluginsDir + item) ) {
        var leftOverFile = fso.GetFile(pluginsDir + item);
        // Check if it still have read-only setting from Perforce
        if ( leftOverFile.Attributes & 1 )
          leftOverFile.Attributes ^= 1;
        fso.DeleteFile(leftOverFile, true);
      }
      f.Copy(pluginsDir);
    } else {
      f.Delete(true)
      if ( !fso.FileExists('GETRESULTS') ) {
        f = fso.CreateTextFile('GETRESULTS', true);
        f.Close();
      }
    }
  }
}

/**
 * Launches the target and waits for it to finish running tests.
 */
function RunTarget(){
  var proc = sh.Exec(targetPath);
  while ( proc.Status == 0 ) {
    if ( fso.FileExists('DONE') ) {
      proc.Terminate();
      fso.DeleteFile('DONE');
    }
    WScript.Sleep(3000);
  }
}

/**
 * Cleans up our mess.
 */
function CleanUp(){
  var testDir = fso.GetFolder(pluginsDir + 'test');
  testDir.Delete(true);
  var optFile = fso.GetFile(pluginsDir + 'optparse.rb');
  optFile.Delete(true);
  var runFile = fso.GetFile(pluginsDir + 'testuprunner.rb');
  runFile.Delete(true);
  var win32oleFile = fso.GetFile(pluginsDir + 'win32ole.so');
  win32oleFile.Delete(true);

  if ( !fso.FileExists('GETRESULTS') ) {
    f = fso.CreateTextFile('GETRESULTS', true);
    f.Close();
  }
}

/**
 * Main script
 */
MoveItems(true);
RunTarget();
MoveItems(false);
