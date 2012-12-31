if ( $args[0] ) {
    $env:JAVA_HOME = $args[0]
    Write-Host "JAVA_HOME has been set to $env:JAVA_HOME"
}
else {
    Write-Host "Usage: set-java.ps1 JAVA_PATH"
}
