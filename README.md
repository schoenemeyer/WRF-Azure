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
In this benchmark from (http://www2.mmm.ucar.edu/wrf/WG2/benchv3) is used. You can download the input files as follows from http://www2.mmm.ucar.edu/WG2bench/conus12km_data_v3 or from Azure Blob Storage
```
wget  https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00
wget  https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00
```

## Performance in Azure

Here is the performance for the CONUS 12km Benchmark you can expect on our H16r series in Azure. The simulation speed can be calculated by running this command after finishing the simulation. For performance measurement you will need the file stats.awk which can be also download from this repository https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/stats.awk 
```
grep 'Timing for main' rsl.error.0000 | tail -149 | awk '{print $9}' | awk -f stats.awk
```
This command will output the average time per time step as the mean value. Simulation speed is the model time step, 72 seconds, divided by average time per time step. You can also derive the sustained Gigaflops per second which is simulation speed times 0.418 for this case.

![After processing](https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/wrf3.8-128.gif)

The Azure H-series virtual machines are built on the Intel Haswell E5-2667 V3 processor technology featuring DDR4 memory and SSD-based temporary storage.

In addition to the substantial CPU power, the H-series offers diverse options for low latency RDMA networking using FDR InfiniBand and several memory configurations to support memory intensive computational requirements.
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-hpc


## Fast Track using Virtual Machine Scale Sets
For the impatient scientist and quick testing, this track gives you the complete software stack for WRF. The WRF zip file contains everything you need to run on Azure H-Series including netcdf etc.. The expected time to finish this exercise is 20 min if you have your subscription and enough quota for H series family.


1. Open a [Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) session from the Azure Portal, or open a Linux session with Azure CLI v2.0, jq and zip packages installed. Here is the link how to install az cli on your workstation https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
2. Clone the repository, `git clone https://github.com/schoenemeyer/WRF3.8-in-Azure.git`
3. Grant execute access to scripts `chmod +x *.sh`
4. Create Virtual Machine Scale Set (https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/overview) for 2, 4, 8 or more nodes. Make sure you have enough quota to run your experiment. You can find on the portal a button for requesting higher core counts

The commands to be executed on your Linux Workstation
```
az login
az account show
```
will show the available ids, e.g. "id": c45f88-90......4r" and the parameter "isDefault" must be true. If you have several ids, make sure to set true to the id, you want to use.
```
az account set -s "your preferred subscription id"
```
Create a resource group that contains your private infrastructure in your preferred region. A list of Azure regions can be found here https://azure.microsoft.com/en-us/global-infrastructure/regions/
```
az group create -n wrflab -l northeurope  

```
Decide for the number of nodes you are going to run, e.g. 2, and you will get a cluster with 2 nodes connected with FDR and CentOS 7.4 images with Intel MPI 5.1.3.223.
```
./vmsscreate.sh 2
```
After the VMSS is created, you will get the command how to connect to the first VM of your cluster
```
ssh username@<ip> -p 50000
```
Doublecheck whether the hostname is correctly set in the hostfile
```
sudo yum -y install centos-release-scl
sudo yum -y install devtoolset-4-gcc*
scl enable devtoolset-4 bash

./install-run-wrf.sh
```
After the simulation you will get a result such as this. "Mean" is the average wallclock time per model time step. That means WRF needs with two nodes in Azure 0.77 sec for 72 sec of model simulation time.
```
    items:       149
      max:         1.318440
      min:         0.698280
      sum:       115.055320
     mean:         0.772183
 mean/max:         0.585680

```

## For production runs we recommend Azure Batch

Usually scientists want to focus on the algorithm, instead of scalability, underlying hardware infrastructure and high availability. [Azure Batch service](https://docs.microsoft.com/en-us/azure/batch/batch-technical-overview) creates and manages a pool of compute nodes (virtual machines), installs the applications you want to run, and schedules jobs to run on the nodes. There is no cluster or job scheduler software to install, manage, or scale. Instead, you use [Batch APIs and tools](https://docs.microsoft.com/en-us/azure/batch/batch-apis-tools), command-line scripts, or the Azure portal to configure, manage, and monitor your jobs.


1. Update the deployment script [deploy_script.sh](https://github.com/lmiroslaw/azure-batch-ilastik/blob/master/deploy_script.sh)
2. U
3

```bash
 tar -cf runme.tar pixelClassification.ilp run_task.sh
 
```
The logic included in a separate runme.tar file and the input data are uploaded separately. The example includes a single input file .h5 that is uploaded multiple times. This way we can simulate real scenario with multiple input files: 



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

## Monitoring your jobs

We encourage to use [BatchLabs](https://github.com/Azure/BatchLabs) for monitoring purposes. In addition, these set of commands will help to deal with problems during the execution.



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

For the WRF model and the input data
The University Corporation for Atmospheric Research
The National Center for Atmospheric Research
The UCAR Community Programs


