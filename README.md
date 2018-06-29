## Introduction

The purpose of this project is to demonstrate the possibility of running WRF3.8  using Azure HPC Infrastructure.
The WRF3.8.1 is a community model maintained by NCAR/UCAR [https://www.mmm.ucar.edu/weather-research-and-forecasting-model ]
WRF has been developed for various scenarios including simulating atmospheric chemistry as described in here https://www.imk-ifu.kit.edu/829.php. The asscociated paper is published in https://www.sciencedirect.com/science/article/pii/S1352231099004021.

This project shows how to run [WRF](http://www2.mmm.ucar.edu/wrf/users/wrfv3.8/wrf_model.html) in the Azure Infrastructure.

The video below shows a typical result of WRF simulating a tropical storm.

![After processing](https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/wrf_atl_shear_anim.gif)

You can also learn about installing WRF in this video

https://www.youtube.com/watch?v=EMO6jreKi6o

## WRF CONUS 12km Benchmark
In this benchmark from (http://www2.mmm.ucar.edu/wrf/WG2/benchv3) is used. You can download the input files as follows  from http://www2.mmm.ucar.edu/WG2bench/conus12km_data_v3 or from Azure Blob Storage
```
wget  https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00
wget  https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00
```

## Performance in Azure

Here is the performance for the CONUS 12km Benchmark you can expect on our H16r series in Azure. The simulation speed can be calculated by running this command after finishing the simulation. Please use the  https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/stats.awk 
```
grep 'Timing for main' rsl.error.0000 | tail -149 | awk '{print $9}' | awk -f stats.awk
```

This command will output the average time per time step as the mean value. Simulation speed is the model time step, 72 seconds, divided by average time per time step. You can also derive the sustained Gigaflops per second which is simulation speed times 0.418 for this case.

![After processing](https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/wrf3.8.gif)

The Azure H-series virtual machines are built on the Intel Haswell E5-2667 V3 processor technology featuring DDR4 memory and SSD-based temporary storage.

In addition to the substantial CPU power, the H-series offers diverse options for low latency RDMA networking using FDR InfiniBand and several memory configurations to support memory intensive computational requirements.
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-hpc


## Fast Track
For the impatient scientist and quick testing, this track gives you the complete software stack for WRF. The WRF zip file contains everything you need to run on Azure H-Series including netcdf etc.

Prerequisite: Azure Subscription 
1. Open a [Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) session from the Azure Portal, or open a Linux session with Azure CLI v2.0, jq and zip packages installed. Here is the link how to install az cli on your workstation https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
2. Create a Storage Account in Azure from the Portal https://ms.portal.azure.com/ 
2. Clone the repository, `git clone https://github.com/schoenemeyer/WRF3.8-in-Azure.git`
3. Grant execute access to scripts `chmod +x *.sh`
4. Create Virtual Machine Scale Set (https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) for 2, 4, 8 or more nodes. Make sure you have enough quota to run your experiment. You can find on the portal a button for requesting higher core counts

The commands to be executed on your Linux Workstation
```
az login
az account show
```
will show the available ids, e.g. "id": c45f88-90......4r" and the "isDefault" must be true. If you have several ids, make sure to set true to the id, you want to use.
```
az account set -s "your preferred subscription id"
```
Decide for the number of nodes you are going to run, e.g. 2
```
./vmsscreate.sh 2
wget https://hpccenth2lts.blob.core.windows.net/wrf/wrf.zip
```

Usually scientists want to focus on the algorithm, instead of scalability, underlying hardware infrastructure and high availability. [Azure Batch service](https://docs.microsoft.com/en-us/azure/batch/batch-technical-overview) creates and manages a pool of compute nodes (virtual machines), installs the applications you want to run, and schedules jobs to run on the nodes. There is no cluster or job scheduler software to install, manage, or scale. Instead, you use [Batch APIs and tools](https://docs.microsoft.com/en-us/azure/batch/batch-apis-tools), command-line scripts, or the Azure portal to configure, manage, and monitor your jobs.

We are assuming you already created the Storage Account as well as the Batch Account using Azure Portal or Azure CLI (see the Troubleshooting section). Following preparation steps must be executed.

1. Update the deployment script [deploy_script.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/deploy_script.sh)
2. Update the [JSON file](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/pool-shipyard.json) with the reference to the  dependencies and the deployment script. Update the container name in the *blobSource* tag. 
3

```bash
 tar -cf runme.tar pixelClassification.ilp run_task.sh
 az storage blob upload -f runme.tar --account-name shipyarddata --account-key longkey== -c drosophila --name runme.tar
 az storage blob upload -f deploy_script.sh --account-name shipyarddata --account-key longkey== -c drosophila --name deploy_script.sh
```
The logic included in a separate runme.tar file and the input data are uploaded separately. The example includes a single input file .h5 that is uploaded multiple times. This way we can simulate real scenario with multiple input files: 

```
for k in {1..2}
do
az storage blob upload -f drosophila_00-49.h5 --account-name shipyarddata --account-key longkey== -c drosophila --name drosophila_00-49_$k.h5
 done
```

4. Edit the script and provide missing Batch Account Name, poolid and execute the script [01.redeploy.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/01.redeploy.sh) as follows:
```
./01.redeploy.sh ilastik
```
where 'ilastik' is the pool name.  The script creates the pool:
```
poolid=ilastik
GROUPID=demorg
BATCHID=matlabb
az batch account login -g $GROUPID -n $BATCHID

az batch pool create --id $poolid --image "Canonical:UbuntuServer:16.04.0-LTS" --node-agent-sku-id "batch.node.ubuntu 16.04"  --vm-size Standard_D11 --verbose
```

assigns a json to a pool
```
az batch pool set --pool-id $poolid --json-file pool-shipyard.json 
```

and resizes the pool. This is the moment when the VMs are provisioned and the deploy_script.sh executes on each machine.
```
az batch pool resize --pool-id $poolid --target-dedicated 2 
```

## Execution Phase

5. Edit the script and provide missing data and execute the script [02.run_job.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/02.run_job.sh) as follows:
```
./02.run_job.sh ilastik
```

The scripts creates a job and $k=2$ tasks on a pool called *ilastik*. Each task calls [run_task.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/run_task.sh) that in turns analyzes a single .h5 file.
```
az batch job create --id $JOBID --pool-id $poolid 
for k in {1..2} 
  do 
    echo "starting task_$k ..."
    az batch task create --job-id $JOBID --task-id "task_$k" --command-line "/mnt/batch/tasks/shared/run_task.sh $k > out.log"
  done

```

6. Once the calculation is ready download the results to your local machine by:
```
03.download_results.sh $jobid
```
where $jobid identifies the job. You can find out this parameter while running [02.run_job.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/02.run_job.sh), from Azure Portal or from BatchLabs.

You can visualize the results in [ImageJ](https://imagej.nih.gov/ij/), [Fiji](https://fiji.sc) or image processing software of your choice.

## Troubleshooting

We encourage to use [BatchLabs](https://github.com/Azure/BatchLabs) for monitoring purposes. In addition, these set of commands will help to deal with problems during the execution.

Run the script and create the admin user on the first node
```
04.diagnose.sh mypassword
```

* Remove the job
> az batch job delete  --job-id $jobid  --account-endpoint $batchep --account-name $batchid --yes

* We can check the status of the pool to see when it has finished resizing.
> az batch pool show --pool-id $poolid  --account-endpoint $batchep --account-name $batchid

* List the compute nodes running in a pool.
> az batch node list --pool-id $poolid --account-endpoint $batchep --account-name $batchid -o table

* List remote login connections for a specific node, for example *tvm-3550856927_1-20170904t111707z* 
> az batch node remote-login-settings show --pool-id ilastik --node-id tvm-3550856927_1-20170904t111707z --account-endpoint $batchep --account-name $batchid -o table

* Remove the pool
> az batch pool delete --pool-id $poolid  --account-endpoint $batchep --account-name $batchid

* Create the resource group and storage account. For example:
 ```
 az group create -n tilastik -l westeurope
 az storage account create -n ilastiksstorage -l westeurope -g tilastik
```
* Get the connection string for the Azure Storage
> az storage account show-connection-string -n ilastiksstorage -g tilastik

* Create the azure batch service
> az batch account create -n bilastik -g tilastik

### Acknowledgement

Data courtesy of Lars Hufnagel, EMBL Heidelberg


