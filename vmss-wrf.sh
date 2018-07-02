#!/bin/bash
#Usage vmsscreate.sh <numberofnodes> 
#Custom IMAGE
echo -n "Do you want to delete the VM Scaleset (y/n)? "
read answerd
if [ "$answerc" != "${answerd#[Nn]}" ] ;then
az vmss delete  --name wrfconus --resource-group wrflab
exit
else
    echo "Scaleset still alive"
fi
echo -n "Do you want to create a new Resource Group Scaleset (y/n)? "
read answera
if [ "$answera" != "${answera#[Yy]}" ] ;then
az group create -n wrflab -l northeurope  
else
    echo "No Resource Group Scaleset created"
fi
echo -n "Do you want to create a new VM Scaleset (y/n)? "
read answerb
if [ "$answerb" != "${answerb#[Yy]}" ] ;then
az vmss create --name wrfconus --resource-group wrflab --image OpenLogic:CentOS-HPC:7.4:7.4.20180301 --vm-sku Standard_H16r --storage-sku Standard_LRS --instance-count $1 --authentication-type ssh  --single-placement-group true --output tsv --disable-overprovision --ssh-key-value /home/thomas/.ssh/id_rsa.pub
else
    echo "No Scaleset created"
fi
echo "List Connection Info "
sleep 10s
rm -f list-instance node1 hostname1
az vmss list-instance-connection-info --name wrfconus --resource-group wrflab >> list-instance
cat list-instance
grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' list-instance >> node1
cat node1
ip=$(head -n 1 node1)
echo "The IP of the master node= " $ip
cat << EOF > ./msglen.txt
2
8
EOF
scp -P 50000 ~/.ssh/id_rsa thomas@$ip:/home/thomas/.ssh
scp -P 50000 ~/.ssh/id_rsa.pub  thomas@$ip:/home/thomas/.ssh
scp -P 50000 ./msglen.txt thomas@$ip:/home/thomas
echo "Connect  ssh thomas@"$ip" -p 50000 "
ssh  thomas@"$ip" -p 50000 /bin/bash << EOF
hostname > hostname1
sudo yum -y install centos-release-scl
sudo yum -y install devtoolset-4-gcc*
EOF
scp -P 50000 thomas@$ip:/home/thomas/hostname1 .
echo "create hostlist" 
namehost=$(cat hostname1)
rm -f hostfile
echo "$namehost" | rev | cut -c 2- | rev > naho
nah=$(cat naho)
for (( i=0; i<$1; i++))
   do
   echo " $nah$i" >> hostfile
   done
cat hostfile
scp -P 50000 ./hostfile thomas@$ip:/home/thomas
echo "create scp-script" 
rm -f install-run-wrf.sh
echo "#!/bin/bash" >> install-run-wrf.sh
echo "ulimit -s unlimited" >> install-run-wrf.sh
echo " export LD_LIBRARY_PATH=./:"'$'"LD_LIBRARY_PATH"  >> install-run-wrf.sh
echo "export INTELMPI_ROOT=/opt/intel/impi/5.1.3.223 " >> install-run-wrf.sh
echo "export I_MPI_FABRICS=shm:dapl " >> install-run-wrf.sh
echo "export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 " >> install-run-wrf.sh
echo "source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh " >> install-run-wrf.sh
echo "scl enable devtoolset-4 " >> install-run-wrf.sh
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrf.zip"  >> install-run-wrf.sh 
echo " unzip wrf"  >> install-run-wrf.sh 
echo " rm wrf.zip"  >> install-run-wrf.sh 
for (( i=1; i<$1; i++))
   do
   echo "scp -r * thomas@wrfco250600000$i:/home/thomas" >> install-run-wrf.sh
   done
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00" >> install-run-wrf.sh
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfbdy_d01" >> install-run-wrf.sh
echo " mpirun -np " $((16*$1)) " -perhost 16 -hostfile ./hostfile ./wrf.exe" >> install-run-wrf.sh
echo " grep 'Timing for main' rsl.error.0000 | tail -149 | awk '{print"' $9'"}' | awk -f stats.awk" >> install-run-wrf.sh
scp -P 50000 ./install-run-wrf.sh thomas@$ip:/home/thomas

echo "export INTELMPI_ROOT=/opt/intel/impi/5.1.3.223 "
echo "export I_MPI_FABRICS=shm:dapl "
echo "export I_MPI_DAPL_PROVIDER=ofa-v2-ib0 "
echo "source /opt/intel/impi/5.1.3.223/bin64/mpivars.sh "

echo " ####################################### "
echo " WRF "
echo " ####################################### "
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrf.zip"
echo " unzip wrf"
echo " rm wrf.zip"
echo " run ./install-run-wrf.sh"
echo " scp -r * thomas@wrfvma244000001:/home/thomas "
echo " export LD_LIBRARY_PATH=./:"'$'"LD_LIBRARY_PATH"
echo " no shared FS needed"
echo " ulimit -s unlimited"
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfrst_d01_2001-10-25_00_00_00"
echo " wget https://hpccenth2lts.blob.core.windows.net/wrf/wrfbdy_d01"
echo " mpirun -np $((16*$1)) -perhost 16 -hostfile ./hostfile ./wrf.exe "
echo " grep 'Timing for main' rsl.error.0000 | tail -149 | awk '{print"' $9'"}' | awk -f stats.awk"

echo "Connect  ssh thomas@"$ip" -p 50000 "
echo "Content of your hostfile "
cat hostfile
echo -n "Do you want to delete the new VM Scaleset (y/n)? "
read answerc
if [ "$answerc" != "${answerc#[Yy]}" ] ;then
az vmss delete  --name wrfconus --resource-group wrflab
else
    echo "Scaleset still alive"
fi
