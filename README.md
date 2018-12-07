## Introduction

The purpose of this project is to demonstrate the possibility of running WRF3.8  using Azure HPC Infrastructure.
The WRF3.8.1 is a community model maintained by NCAR/UCAR [https://www.mmm.ucar.edu/weather-research-and-forecasting-model ]

The source code is available from this repository https://github.com/NCAR/WRFV3/releases.
In order to run this lab, it is not necessary to compile the model. The binaries for CentOS 7.4 will be automatically downloaded from Azure Blob Storage.

## WRF CONUS 12km Benchmark
The inpudata for this benchmark can be obtained from (http://www2.mmm.ucar.edu/WG2bench/conus12km_data_v3/ . 
The details and description of the benchmark can be found here : http://www2.mmm.ucar.edu/wrf/WG2/benchv3/#_Toc212961288 

## How to run

Create a H16r VM in Azure with Centos 7.4 (this VM also includes FDR InfiniBand with the necessary IB drivers and Intel MPI)

Login to the machine with ssh username@<id-adress>
```
wget https://hpccenth2lts.blob.core.windows.net/wrf/wrf.zip
wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00
wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfbdy_d01

unzip wrf.zip

export LD_LIBRARY_PATH=./:$LD_LIBRARY_PATH  
export INTELMPI_ROOT=/opt/intel/impi/5.1.3.223 
source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh 
sudo yum -y install centos-release-scl
sudo yum -y install devtoolset-6-gcc*

mpirun -np 16 ./wrf.exe
```

## Performance in Azure

The figure below shows the performance for the CONUS 12km Benchmark you can expect on our H16r series in Azure. The simulation speed can be calculated by running this command after finishing the simulation. For performance measurement you will need the file stats.awk which can be also download from this repository https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/stats.awk 
```
grep 'Timing for main' rsl.error.0000 | tail -149 | awk '{print $9}' | awk -f stats.awk
```
This command will output the average time per time step as the mean value. Simulation speed is the model time step, 72 seconds, divided by average time per time step. You can also derive the sustained Gigaflops per second which is simulation speed times 0.418 for this case.

![After processing](https://github.com/schoenemeyer/WRF3.8-in-Azure/blob/master/wrf3.8-256.gif)

The Azure H-series virtual machines are built on the Intel Haswell E5-2667 V3 processor technology featuring DDR4 memory and SSD-based temporary storage.

In addition to the substantial CPU power, the H-series offers diverse options for low latency RDMA networking using FDR InfiniBand and several memory configurations to support memory intensive computational requirements. H-Series machines in Azure are running with HT disabled.
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
Decide for the number of nodes you are going to run, e.g. 2, and you will get a cluster with 2 nodes connected with FDR and CentOS 7.4 images with Intel MPI 5.1.3.223. Make sure you set your username correctly in the third line in the script vmss-wrf.sh.
```
./vmss-wrf.sh 2
```
After the VMSS is created, you will get the command how to connect to the first VM of your cluster
```
ssh username@<ip> -p 50000
```
Doublecheck whether the hostname is correctly set in the hostfile and start installation and running the benchmark:
```
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

You can visit the this lab https://github.com/schoenemeyer/WRF3.8.1-in-Azure-Batch to learn how to run WRF in Azure Batch

### Acknowledgement

For the WRF model and the input data
The University Corporation for Atmospheric Research
The National Center for Atmospheric Research
The UCAR Community Programs


