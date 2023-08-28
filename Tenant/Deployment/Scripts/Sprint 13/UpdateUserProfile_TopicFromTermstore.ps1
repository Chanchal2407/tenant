#
#    Alfa Laval
#    Task 5779 : Create script to Iterate through User profile User subscription and do needed changes
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$oldGUIDs = @("df260062-e16c-4417-a8d7-4f01d1d96e85","9c6ae24f-619b-4231-a752-30ede008580f","629fa943-35aa-4f8b-93f2-ecc9d3a05fd1","47ebcb08-be38-43a3-a933-27d6fd4657b0","f33df79a-871c-44ff-bb2e-82b52df7131c","0b2c9df8-c478-48b7-be34-a9d8a81d7908","70d58175-d5a5-4722-aa76-8455de7f196b","d7c7507c-e6e8-4771-be66-964cf0b26fb2","6c9bbc56-fcf4-46ac-a7da-c05743dc7fd2","d528fad7-1b2f-4272-8439-703e8812f19e","c1cc06a2-b514-40da-a232-b405f090ae77","aeecdcc7-9533-4ef7-999c-e10d782efbf9","3696564a-13be-4dac-906e-a777c2bbe823","e73340a5-2c63-46e8-9760-ce5f23743374")
$newGUIDS = @("abb2d466-140b-4a04-92a0-12af6b682d0c","daa9c314-98ce-4de2-a2bf-37e4334bfbc3","d25d7a51-ce47-4bd0-a6ce-23cfb1ba5f1f","596a8d5c-8f86-4b0c-bff1-fb1aa633767d","f0641a8d-9236-4fe9-bb9b-71dd53fec95c","2b31be0f-d1d2-4238-848b-7ab54e261633","c4c8e18d-f7fa-4695-b211-fddff37d6f5b","ae6ef48c-d3c2-466b-aca3-e22bf18617a0","87d41f29-4c75-4f85-b8c2-1bc5fb9c5fa3","73504a7f-2fac-43e3-bb4d-801c4bffe734","379a699f-736d-40c9-8114-983893246ad9","40cd373c-7abd-4b7d-8f20-4f9d0bb5174f","3535b34b-2021-4c7a-aa93-5b8326e628b2","8af59fb2-15f9-4d05-8047-ba9f2159a11a")

$output = $PSScriptRoot + "\logs\T5779_output_v2.txt"

# ------------ process data ------------
# estimated ~40k user accounts - pager is needed
$pagger = 0
$step = 300
$profilesupdated = 0
do
{
    # get all user accounts
    $users = Submit-PnPSearchQuery -Query "*" -SourceId "B09A7990-05EA-4AF9-81EF-EDFAB16C4E31" -SelectProperties @("PreferredName","RefinableString44") -RelevantResults -StartRow $pagger -MaxResults $step
    if($users.Count -eq 0) { break; }

    foreach($user in $users)
    {
        try
        {
            #$message = "{0:yyyy-MM-dd HH:mm:ss.fff}" -f (get-date) + " --- " + $user.AccountName

            # check if user has topics to update
            $userTopics = $user.RefinableString44.Split(';').Trim()
            $regionsToUpdate = Compare-Object $userTopics $oldGUIDs -IncludeEqual -ExcludeDifferent | % { $_.inputobject }
            if ($regionsToUpdate.Count -eq 0) {
                continue
            }

            # get all properties and checks if "Topic" and "Topic IDs" exist
            $upp = Get-PnPUserProfileProperty -Account $user.AccountName
            if($upp.UserProfileProperties -ne $null -AND $upp.UserProfileProperties.ContainsKey("ShareTopics") -AND $upp.UserProfileProperties.ContainsKey("ShareTopicsIDs"))
            {
                # these fields could contain multiple values
                $userTermIds = $upp.UserProfileProperties.Item("ShareTopicsIDs")

                Write-Host "[" $user.AccountName "]"
                Write-Host "[$userTermIds]"

                # replace GUIDS
                for($i=0; $i -le $oldGUIDs.Count; $i++) 
                {
                    $userTermIds = $userTermIds.Replace($oldGUIDs[$i],$newGUIDS[$i])
                }

                # print new values
                Write-Host "[$userTermIds]"
                Write-Host ""

                # format string
                $newTermGuidArray = $userTermIds.Split("|")

                # update user properties
                Set-PnPUserProfileProperty -Account $user.AccountName -PropertyName "ShareTopics" -Values $newTermGuidArray
                Set-PnPUserProfileProperty -Account $user.AccountName -PropertyName "ShareTopicsIDs" -Values $newTermGuidArray
                $profilesupdated++
            }
            else
            {
                Write-Host "  ERROR-1 : Properties [Topics] and/or [TopicIDs] not found"
            }

        }
        catch [System.Exception]
        {
            Write-Host "ERROR-4 : Unknown exception" $_.Exception
        }
    }
    $pagger = $pagger + $step
}
until ($users.Count -eq 0)

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host "Total profiles updated: $profilesupdated"
Write-host " "