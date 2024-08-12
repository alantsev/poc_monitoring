# Define the Data Collector Set parameters
$collectorSetName = "NetworkAndProcessMonitoring"
$logPath = "C:\PerfLogs\$collectorSetName"
$durationInHours = 72  # Adjust the duration as needed

# Function to log process start/stop events
function Start-ProcessTrace {
    $traceFile = "$logPath\ProcessTrace.log"

    Register-WmiEvent -Class Win32_ProcessStartTrace -Action {
        $eventDetails = "Process Started: " + $Event.SourceEventArgs.NewEvent.ProcessName + " - " + (Get-Date)
        Add-Content -Path $traceFile -Value $eventDetails
    } -SourceIdentifier ProcessStartTrace

    Register-WmiEvent -Class Win32_ProcessStopTrace -Action {
        $eventDetails = "Process Stopped: " + $Event.SourceEventArgs.NewEvent.ProcessName + " - " + (Get-Date)
        Add-Content -Path $traceFile -Value $eventDetails
    } -SourceIdentifier ProcessStopTrace
}

# Create Data Collector Set
New-PerfMonitorDataCollectorSet -Name $collectorSetName -OutputPath $logPath

# Add counters (example for network traffic and process performance)
Add-Counter -Counter "\Process(*)\ID Process" -CollectorSet $collectorSetName
Add-Counter -Counter "\Process(*)\% Processor Time" -CollectorSet $collectorSetName
Add-Counter -Counter "\Network Interface(*)\Bytes Received/sec" -CollectorSet $collectorSetName
Add-Counter -Counter "\Network Interface(*)\Bytes Sent/sec" -CollectorSet $collectorSetName
Add-Counter -Counter "\TCPv4\Connections Established" -CollectorSet $collectorSetName
Add-Counter -Counter "\TCPv6\Connections Established" -CollectorSet $collectorSetName

# Start the Data Collector Set
Start-PerfMonitorDataCollectorSet -Name $collectorSetName

# Start process trace logging
Start-ProcessTrace

# Schedule to stop after the desired duration
Start-Sleep -Seconds (3600 * $durationInHours)

# Stop the Data Collector Set
Stop-PerfMonitorDataCollectorSet -Name $collectorSetName

# Unregister WMI events
Unregister-Event -SourceIdentifier ProcessStartTrace
Unregister-Event -SourceIdentifier ProcessStopTrace

# Compress and send the log files to a central server
Compress-Archive -Path "$logPath\*" -DestinationPath "$logPath.zip"
# Replace 'CentralServer' with your actual server name or IP
Copy-Item -Path "$logPath.zip" -Destination "\\CentralServer\SharedFolder\$env:COMPUTERNAME-$collectorSetName.zip"

