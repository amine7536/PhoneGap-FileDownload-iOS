//
//  FileDownload.js
//  FileDownLoadApp
//

function FileDownload() {
}

FileDownload.prototype.downloadFile = function(url, destFileName, destPath, success, fail, progress) 
{        
    PhoneGap.exec("FileDownload.downloadFile", url, destFileName, destPath, GetFunctionName(success), GetFunctionName(fail), GetFunctionName(progress) );
};

PhoneGap.addConstructor(function() 
{
    window.fileDownloadMgr = new FileDownload();
});
