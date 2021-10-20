

$correction_python_code = 'C:\\users\\Noora\\Documents\\FlatCorrection.py' #Address to the python code that normalizes the data


function Run-Recon {
    Param([string]$samplename,[string]$foldername)
    
    $origname = "Z:\\$samplename.h5"
    $flatname = "Z:\\flat_fields_$samplename.h5"
    $correctedname = "Y:\\$foldername\\$samplename.h5"
    $fname = $correctedname # feeding the out put of correction as an input to the reconstruction
    $outname = "C:\Users\Noora\Desktop\corrected_rec\$foldername\$samplename" # Address to the out put folder for recunstruction
    
    if ($script:correction_flag){
        $script:length = $((python $script:correction_python_code $origname $flatname $correctedname) 2>&1)
    }


    if ($script:centerfinding_flag){
        tomopy recon --file-name $fname --reconstruction-type try --rotation-axis-auto manual --center-search-width 50 --output-folder $outname --flat-correction-method none
    }


    if ($script:recon_flag){
        $Start_loop_S = Get-Date
        for ($i = 0; $i -lt $script:length; $i += $script:chunk) 
        {
            $start = $i
            if ($i+$script:chunk -gt $script:length)
            {
                $end = $script:length
            }
            else
            {
                $end = $i+$script:chunk
            }
            Write-Output "Processed proj set $i out of $script:length start-end $start-$end"
            $start_s = Get-Date
            tomopy recon --file-name $fname --reconstruction-type full --start-proj $start --end-proj $end --rotation-axis-auto manual --flat-correction-method none --rotation-axis $script:center --output-folder "$outname\$end" --nsino-per-chunk 128 --binning $script:binning --remove-stripe-method fw --zinger-removal-method standard #--output-format hdf5 #2>$null #3>$null 

            $end_s = Get-Date
            Write-Output "----> this reconstruction took: $((New-TimeSpan -Start $start_s -End $end_s).TotalSeconds) seconds"
        }
        $End_Loop_S = (Get-Date)
        Write-Output "This Script took $((New-TimeSpan -Start $Start_Loop_S -End $End_Loop_S).TotalSeconds) seconds to run for $script:length projections."
        "$samplename     $length" | Out-File -FilePath "C:\Users\Noora\Desktop\corrected_rec\length_log.txt" -Append
    }
}


$correction_flag = 1 # Set this variable to 1 if you want the data to be corrected
$centerfinding_flag = 0 # Set this variable to 1 if you would like to run manual center finding
$recon_flag = 1 # Set this variable to 1 if you would like to run full recunstruction

$binning = 2

$foldername = 's06_ethanol'

$samplename = 's06_3d_ethanol_156'
$center = 1220
Run-Recon -samplename $samplename -foldername $foldername

$samplename = 's06_3d_ethanol_157'
$center = 1216
Run-Recon -samplename $samplename -foldername $foldername






























# tomopy recon --file-name C:\Users\YOUR USERNAME\awesome_data\tooth.h5 --reconstruction-type try --rotation-axis-auto manual --center-search-width 50
# tomopy recon --file-name Y:\\s09\\s09_3d_181.h5 --reconstruction-type try --rotation-axis-auto manual --center-search-width 50 --output-folder C:\Users\Noora\Desktop\corrected_rec\try_center\s09_3d_181 --flat-correct

<#
$darkname = "Z:\dark_fields_s01plus_3d_161.h5" #1280
$darkname = "Z:\dark_fields_$samplename.h5"

tomopy convert --old-projection-file-name $projname --old-white-file-name $flatname --old-dark-file-name $darkname

$startx = 0
$starty = 0
$endx = 256
$endy = 180

tomopy flat_drift_correction --file-name $projname --average-shift-per-chunk True --nproj-per-chunk 200 --flat-region-startx $startx --flat-region-starty $starty --flat-region-endx $endx --flat-region-endy $endy
#>