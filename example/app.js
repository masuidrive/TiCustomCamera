// This is a test harness for your module
// You should do something interesting in this harness 
// to test out the module and to provide instructions 
// to users on how to use it by example.


// open a single window
var window = Ti.UI.createWindow({
  backgroundColor:'white'
});
window.open();

var CustomCamera = require('CustomCamera');
CustomCamera.open({});
/*
CustomCamera.take();
CustomCamera.close();
var blob = CustomCamera.viewToBlob(view);
*/