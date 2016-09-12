function parseWeexVersion(data){
    $(".version.android span").text(data.androidVersion)
    $(".version.ios span").text(data.iosVersion)

    $(".link.android").click(function(){window.open(data.androidDownload,"playgroundDownloadTarget");})
    $(".link.ios").click(function(){window.open(data.iosDownload,"playgroundDownloadTarget");})    
    
}

window.parseWeexVersion = parseWeexVersion;
