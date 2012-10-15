// Copyright 2012 Trimble Navigation Ltd.
// Apache License, version 2.0

/**
 * @fileoverview This file contains all the script logic for run_tests_gui.hta.
 * @author Matt Lowrie
 * @version 0.1
 */
 
/**
 * Script utilities
 */
var sh = new ActiveXObject("WScript.Shell");
var fso = new ActiveXObject("Scripting.FileSystemObject");

/**
 * Global namespace variables
 * RTHTA: Run Tests HTA.
 */
var RTHTA_fileNames = {
    'manifest' : 'test_cases.man',
    'testRootDir' : 'tests',
    'testCaseDir' : 'sketchup\\test_cases',
    'resultsDir' : 'results',
    'prefs' : 'prefs'
  }
var RTHTA_prefs = { 'user':{}, 'session':{} };

/**
 * Initialize the HTA.
 */
function init(){
  readPrefs();
  findTarget();
  initGui();
}

/**
 * Reads in user preferences and loads them into the global object.
 */
function readPrefs(){
  if ( fso.FileExists( RTHTA_fileNames.prefs ) ) {
    var prefsFile = fso.OpenTextFile(RTHTA_fileNames.prefs, 1, false);
    if ( !prefsFile.AtEndOfStream ) {
      var buffer = prefsFile.ReadAll();
      var prefs = buffer.split('\r\n');
      for ( var i = 0; i < prefs.length; ++i ) {
        var currentPref = prefs[i].split('=');
        RTHTA_prefs.user[ currentPref[0] ] = currentPref[1];
      }
      show = [];
      for ( var p in RTHTA_prefs.user ){
        show.push(p + ": " + RTHTA_prefs.user[p]);
      }
    }
    prefsFile.Close();
  } else {
    var newFile = fso.CreateTextFile(RTHTA_fileNames.prefs);
    newFile.Close();
    var pf = fso.GetFile(RTHTA_fileNames.prefs);
    // Make it a hidden file
    pf.Attributes += 2;
  }
}

/**
 * Discover the location of the target.
 */
function findTarget(){
  var width = 0;
  // Just checking for SketchUp version 6 through 10 for now...
  for ( var ver = 10; ver >= 6; --ver ) {
    var strBuilder = [];
    strBuilder.push('HKCU\\Software\\Google\\SketchUp');
    strBuilder.push(ver);
    strBuilder.push('\\File Locations\\ComponentBrowser');
    var key = strBuilder.join('');
    var val = null;
    try {
      val = sh.RegRead(key);
    } catch(e){}
    if ( val != null ) {
      var targetDir = val.split("Components");
      var targetPath = targetDir[0] + 'SketchUp.exe';
      width = (val.length > width) ? val.length : width;
      var opt = document.createElement('option')
      opt.innerHTML = targetPath;
      opt.value = targetPath;
      RTHTA_elements.target.appendChild(opt);
      val = null;
    }
  }
  if ( width == 0 ){
    var opt = document.createElement('option');
    var txt = 'Could not find any versions of SketchUp run on this machine.';
    opt.innerHTML = txt;
    opt.value = ''; // No value designates this as an invalid option
    RTHTA_elements.target.appendChild(opt);
    width = txt.length;
  }
  // The 9 multiplier has no signifigance other than it looked correct.
  RTHTA_elements.target.style.width = width * 9;
  var selIndex = RTHTA_elements.target.selectedIndex
  var selPath = RTHTA_elements.target[selIndex].value;
  RTHTA_prefs.session.target = selPath;
}

/**
 * Reads all of the test cases and creates a GUI to select them.
 */
function initGui(){
  // TODO(mlowrie): Eventually we will account for test suites,
  // but for now just diplay test cases for SketchUp.
  var testCaseObj = parseTestCaseDir();
  createGuiElements(testCaseObj);
}

/**
 * Creates an object representing the test case directory.
 * @return An object containing all data needed from the test case directory.
 */
function parseTestCaseDir(){
  var testCaseObj = {};

  var strBuilder = [];
  strBuilder.push(RTHTA_fileNames.testRootDir);
  strBuilder.push('\\');
  strBuilder.push(RTHTA_fileNames.testCaseDir);
  var testCaseDirPath = strBuilder.join('');

  var testCaseDir = fso.GetFolder(testCaseDirPath);
  var dirEnum = new Enumerator(testCaseDir.SubFolders);
  for ( ; !dirEnum.atEnd(); dirEnum.moveNext() ) {
    var currentDir = dirEnum.item();
    var dirName = currentDir.Name;
    testCaseObj[dirName] = {};
    testCaseObj[dirName].tabName = dirName.replace(/_/g, ' ');
    testCaseObj[dirName].files = {};
    var fileEnum = new Enumerator(currentDir.Files);
    for ( ; !fileEnum.atEnd(); fileEnum.moveNext() ){
      var currentFile = fileEnum.item();
      testCaseObj[dirName].files[currentFile.Name] = currentFile.Path;
    }
  }
  return testCaseObj;
}

/**
 * Builds the tab navigation and corresponding view elements.
 */
function createGuiElements(testCaseObj){
  // Main navigation div element
  var divNav = document.createElement('div');
  divNav.id = 'divTestCaseNav';
  divNav.className = 'nav';

  // Unordered list element for tabbed navigation
  var ulNav = document.createElement('ul');
  ulNav.id = 'ulTestCaseNav';

  for ( var dirName in testCaseObj ) {
    // Save the first directory as the selected tab for now
    if ( !RTHTA_prefs.session.selectedTab )
      RTHTA_prefs.session.selectedTab = dirName;

    var li = document.createElement('li');

    var anchor = document.createElement('<a onclick="tabClick(this)">');
    anchor.href = '#';
    anchor.id = dirName;
    anchor.innerHTML = testCaseObj[dirName].tabName;
    
    li.appendChild(anchor);
    ulNav.appendChild(li);
    
    createView(dirName, testCaseObj[dirName].files);
  }

  divNav.appendChild(ulNav);
  // Views are already attached, so insert the nav before all elements
  RTHTA_elements.gui.insertBefore( divNav, RTHTA_elements.gui.childNodes(0) );
  
  // Set the currently selected tab based on preferences
  if ( RTHTA_prefs.user.tab ) {
    getElement(RTHTA_prefs.user.tab).className = 'on';
    getElement('v_' + RTHTA_prefs.user.tab).style.display = '';
    RTHTA_prefs.session.selectedTab = RTHTA_prefs.user.tab;
  } else {
    getElement(RTHTA_prefs.session.selectedTab).className = 'on';
    getElement('v_' + RTHTA_prefs.session.selectedTab).style.display = '';
  }
}

/**
 * Create a selectable GUI for all files in a specific directory.
 */
function createView(dirName, fileList){
  // Create a corresponding view of test cases
  var divView = document.createElement("div");
  divView.id = 'v_' + dirName;
  divView.className = 'view';
  divView.style.display = 'none';

  for ( var fileName in fileList ) {
    var checkbox = document.createElement('<input checked>');
    checkbox.type = 'checkbox';
    checkbox.id = 'cbx_' + fileName;
    checkbox.alt = fileList[fileName];
    
    var item = document.createElement('<a onclick="toggleResults(this.id)">');
    item.href='#';
    item.id = fileName;
    item.innerHTML = fileName;
    
    var resultDiv = document.createElement('div')
    resultDiv.id = fileName + '_results';
    resultDiv.className = 'result';
    resultDiv.innerHTML = '<span style="color:#666">Not run</span>';
    resultDiv.style.display = 'none';

    var lineBreak = document.createElement('br');
    
    divView.appendChild(checkbox);
    divView.appendChild(item);
    divView.appendChild(lineBreak);
    divView.appendChild(resultDiv);
  }
  // Attach the view even if there are no files because 
  // we need the css style to complete the GUI.
  RTHTA_elements.gui.appendChild(divView)
}

/**
 * Handler for when a navigation tab is clicked.
 */
function tabClick(anchor){
  if ( anchor.id == RTHTA_prefs.session.selectedTab )
    return;
    
  var prevSelectedTab = getElement(RTHTA_prefs.session.selectedTab);
  prevSelectedTab.className = '';
  anchor.className = 'on';
  RTHTA_prefs.session.selectedTab = anchor.id;
  savePref('tab', anchor.id);
  
  var allDivs = RTHTA_elements.gui.getElementsByTagName('div');
  for ( var i = 0; i < allDivs.length; ++i ) {
    var theDiv = allDivs[i];
    if ( theDiv.className == 'view' )
      theDiv.style.display = ('v_' + anchor.id == theDiv.id) ? '' : 'none';
  }
}

/**
 * Save a user pref to the prefs file.
 */
function savePref(key, val){
  var pf = fso.OpenTextFile(RTHTA_fileNames.prefs, 1 /* forReading */);
  var buffer = [];
  while ( !pf.AtEndOfStream ){
    var line = pf.ReadLine();
    if ( line.substr(0, key.length) != key ) {
      buffer.push(line);
    }
  }
  buffer.push(key + '=' + val);
  pf.Close();
  var pf = fso.OpenTextFile(RTHTA_fileNames.prefs, 2 /* forWriting */);
  pf.Write( buffer.join('\n') );
  pf.Close();
}

function toggleResults(testCase){
  var resultDiv = getElement(testCase + '_results');
  resultDiv.style.display = (resultDiv.style.display == '') ? 'none' : '';
}

/**
 * Saves a manifest file of all the selected test cases.
 * @return {Boolean} True/False whether any tests to run (manifest saved).
 */
function saveTestCaseManifest(){
  var returnBool = false;
  var checkedTests = findCheckedTests();
  if ( 0 != checkedTests.length ){
    if ( fso.FileExists(RTHTA_fileNames.manifest) )
      fso.DeleteFile(RTHTA_fileNames.manifest);
    var openForWriting = 2;
    var createNew = true;
    var manFile = fso.OpenTextFile(
        RTHTA_fileNames.manifest, 
        openForWriting, 
        createNew
      );
    manFile.Write( checkedTests.join('\n') );
    manFile.Close();
    returnBool = true;
  } else {
    var msg = '<span class="statusWarn">' +
        'Please select test cases to run.</span>';
    RTHTA_elements.display.innerHTML = msg;
  }
  return returnBool;
}

/**
 * Iterates all checkbox UI elements and returns a list of test cases the
 * user has selected.
 * @return {Array} An array of alt tag values from each checked checkbox in 
 * the GUI. Each indicie contains the full file path of the corresponding test
 * case file. An empty array is returned if no GUI checkboxes are selected.
 */
function findCheckedTests(){
  var returnArray = [];
  var divs = RTHTA_elements.gui.getElementsByTagName('div');
  for ( var divIndex = 0; divIndex < divs.length; ++divIndex ) {
    var currentDiv = divs[divIndex];
    if ( currentDiv.className == 'view' && currentDiv.style.display == '' ) {
      var inputs = currentDiv.getElementsByTagName("input");
      for ( var inputIndex = 0; inputIndex < inputs.length; ++inputIndex ) {
        if (inputs[inputIndex].checked )
          returnArray.push( inputs[inputIndex].getAttribute("alt") );
      }
    }
  }
  return returnArray;
}

/**
 * Runs the test script as separate process, so that the HTA GUI
 * is still responsive in order to cancel the script execution.
 */
function runTestProcess(){
  if ( RTHTA_prefs.session.target != '' ){
    var scriptToRun = 'wscript res\\run_tests.js /path:"' + 
        RTHTA_prefs.session.target + '"';
    var normalWindowStyle = 1;
    var waitForExit = false;
    sh.Run(scriptToRun, normalWindowStyle, waitForExit);
  } else {
    RTHTA_elements.display.innerHTML = '<span class="statusWarn">' +
        'No target selected.</span>';
    toggleTargetFilePicker();
  }
}

/**
 * Looks for the signal that the results file is ready.
 */
function checkForResultsFile(){
  if ( fso.FileExists("GETRESULTS") ){
    parseResults();
    fso.DeleteFile("GETRESULTS");
  } else {
    setTimeout(checkForResultsFile, 500);
  }
}

/**
 * Reads the unit test result file and formats it for display in the GUI.
 */
function parseResults(){
  resetChecklist();

  // We've got the results so we can clean up the manifest file now
  if ( fso.FileExists(RTHTA_fileNames.manifest) )
    fso.DeleteFile(RTHTA_fileNames.manifest);

  // First sort all of the result directory names so we can find the latest
  var dirNames = [];
  var resultDirs = fso.GetFolder(RTHTA_fileNames.resultsDir).SubFolders;
  var dirEnum = new Enumerator( resultDirs );
  for ( ; !dirEnum.atEnd(); dirEnum.moveNext() ) {
    dirNames.push( dirEnum.item().Path );
  }
  function revOrder(a,b){ return ( a > b ) ? -1 : ( ( a < b ) ? 1 : 0 ); }
  dirNames.sort(revOrder);

  var failCount = 0;
  var passCount = 0;
  var warnCount = 0;
  
  // Parse each result file in the latest results directory
  // and display it on its associated GUI element
  var latestResult = fso.GetFolder(dirNames[0]);
  var fileEnum = new Enumerator(latestResult.Files);
  for ( ; !fileEnum.atEnd(); fileEnum.moveNext() ) {
    var output = [];
    var elementId = null;
    var failMsgComingNext = false;
    var currentFile = fileEnum.item();
    var status = { 'fail':false, 'pass':false, 'warn':false };
    
    var rawFileLink = [];
    rawFileLink.push('<a href="#" onclick="launchInNotepad(\'');
    rawFileLink.push(currentFile.Path.replace(/\\/g, '\\\\'));
    rawFileLink.push('\');" style="text-decoration:underline">');
    rawFileLink.push('Raw results file</a><br />');
    output.push(rawFileLink.join(''));

    var f = fso.OpenTextFile(currentFile);
    while ( !f.AtEndOfStream ) {
      var line = f.ReadLine();
      if ( /^Loaded suite/.test(line) ) {
        var splitLine = line.split(' ');
        elementId = splitLine[splitLine.length - 1] + '.rb';
/*        line = '';
      } else if ( /^Started/.test(line) ){
        line = '';
*/
      }
      // Check the status of each line that begins with test_
      else if ( /^test_/.test(line) ) {
        if ( /F$/.test(line) ) {
          failCount += 1;
          status.fail = true;
          line = '<span style="background-color:#fcc">' + line + '</span>';
        } else if ( /\.$/.test(line) ) {
          passCount += 1;
          status.pass = true;
          line = '<span style="background-color:#cfc">' + line + '</span>';
        } else if ( /E$/.test(line) ) {
          warnCount += 1;
          status.warn = true;
        } else {
          line = '';
        }
        output.push(line);
      }
      // Check if the following line contains a assertion failure message
      else if ( /]:\s*$/.test(line) ) {
        failMsgComingNext = true;
      } else if ( failMsgComingNext && !/^</.test(line) && !/----/.test(line) ) {
        line = '<span class="failMsg">' + line + '</span>';
        output.push(line);
      } else if ( /^Note/.test(line) ) {
        line = '<span class="failMsg">' + line + '</span>';
        output.push(line);
      } else {
        failMsgComingNext = false;
      }
//      output.push(line);
    }
    f.Close();

    var e = getElement(elementId);
    var er = getElement(elementId + '_results');

    er.innerHTML = output.join('<br />');

    if ( status.fail ) {
      e.className = 'fail';
      //er.style.display = '';
    } else if ( status.warn ) {
      e.className = 'warn';
      //er.style.display = '';
    } else if ( status.pass ) {
      e.className = 'pass';
    } else {
      // The class that says, What happened here???
      e.className = 'wtf';
      //er.style.display = '';
    }
  }

  var msg = [];
  msg.push('<span class="pass">Pass:</span> ');
  msg.push(passCount);
  msg.push(', <span class="fail">Fail:</span> ');
  msg.push(failCount);
  msg.push(', <span class="warn">Warn:</span> ');
  msg.push(warnCount);
  msg.push('. Time: ');
  msg.push( parseRunTime() );
  RTHTA_elements.display.innerHTML = msg.join('');
}

/**
 *  Calculate the time of this test run.
 */
function parseRunTime(){
  var time = 'unknown';
  var now = new Date();
  var runTime = now - RTHTA_prefs.session.runStartTime;
  if ( runTime < 60000 ) {
    time = (runTime / 1000).toString() + ' sec.';
  }
  return time;
}

/**
 * Resets the background color and results display in the GUI to blank.
 */
function resetChecklist(){
  var divs = RTHTA_elements.gui.getElementsByTagName('div');
  for ( var divIndex = 0; divIndex < divs.length; ++divIndex ) {
    var currentDiv = divs[divIndex];
    if ( currentDiv.className == 'view' ) {
      var anchors = currentDiv.getElementsByTagName("a");
      for ( var anchorIndex = 0; anchorIndex < anchors.length; ++anchorIndex ) {
        anchors[anchorIndex].style.backgroundColor = '';
        anchors[anchorIndex].className = '';
      }
      var resultDivs = currentDiv.getElementsByTagName("div");
      for ( var anchorIndex = 0; anchorIndex < anchors.length; ++anchorIndex ) {
        anchors[anchorIndex].style.backgroundColor = '';
      }
    } else if ( currentDiv.className == 'result' ) {
      currentDiv.innerHTML = '<span style="color:#666">Not run</span>';
      currentDiv.style.display = 'none';
    }
  }
}

/**
 * Launch a file path in notepad. Backslashes in file path should 
 * be pre-escaped before passing here as an argument.
 */
function launchInNotepad(path){
  var cmd = 'notepad.exe "' + path + '"';
  sh.Run(cmd, 1, false);
}

/**
 * Cross-browser element getter.
 */
function getElement(id) {
  if(document.getElementById && document.getElementById(id)) {
    return document.getElementById(id);
  }
  else if (document.all && document.all(id)) {
    return document.all(id);
  }
  return false;
}

