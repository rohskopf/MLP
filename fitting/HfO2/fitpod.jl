cdir = pwd(); ii = findlast("MLP", cdir); MLPpath = cdir[1:ii[end]] * "/";    
include(MLPpath * "src/setup.jl");

using DelimitedFiles

# path to the database 
datapath = "../../data/HfO2/"
dataformat = "extxyz"
fileextension = "xyz"
atomspecies = ["Hf", "O"];

# weights for energies, forces, and stresses in the linear fit
weightinner=[100  1  0.0]

# weights for energies, forces, and stresses in the outer nonlinear optimization
weightouter = [0.8, 0.2, 0.0]

# randomly selecting the configurations in the database
randomize = false;

# use all the data 
percentage = 100.0;

# translate atom positions 
translationvector = nothing

# rotate atom positions 
rotationmatrix = nothing

# transpose lattice vectors 
transposelattice = false 

# training data 
traindata[1] = adddata(datapath * "training", dataformat, fileextension, 
            percentage, randomize, atomspecies, weightinner[1,:], translationvector, 
            rotationmatrix, transposelattice)

# validation data 
validdata[1] = adddata(datapath * "validation", dataformat, fileextension, 
            percentage, randomize, atomspecies, weightinner[1,:], translationvector, 
            rotationmatrix, transposelattice)

# testing data 
testdata[1] = adddata(datapath * "test", dataformat, fileextension, 
                percentage, randomize, atomspecies, weightinner[1,:], translationvector, 
                rotationmatrix, transposelattice)

# Descriptors optional parameters
Doptions = DescriptorsOptions(pbc = [1, 1, 1], normalizeenergy=true, normalizestress=true)

# loss function style must be: "energy", "force", "energyforce", "energyforcestress"
lossfunc = "energyforce"

# use least-square method
method = "lsq" 

# cut-off radius
rcut = 5.8

# inner radius 
rin = 1.0

# optimization parameters
optim = setoptim(lossfunc, method)

# Bessel scaling parameters
gamma = [0.0, 2, 4]

j = 2;
# POD Descriptors
if j == 0
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[2,4], nbasis = [2], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[2,2,2], nbasis = [1, 2], rin = rin, rcut=rcut, gamma0 = gamma)
elseif j == 1
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[2,6], nbasis = [3], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[2,4,3], nbasis = [3, 3], rin = rin, rcut=rcut, gamma0 = gamma)
elseif j==2
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[3,6], nbasis = [6], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[3,6,4], nbasis = [5, 4], rin = rin, rcut=rcut, gamma0 = gamma)
elseif j==3 
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[4,6], nbasis = [8], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[4,6,5], nbasis = [8, 5], rin = rin, rcut=rcut, gamma0 = gamma)
elseif j==4
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[6,8], nbasis = [11], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[6,8,7], nbasis = [10, 7], rin = rin, rcut=rcut, gamma0 = gamma)
elseif j==5           
    descriptors[1] = POD(nbody=2, species = [:Hf,:O], pdegree=[6,12], nbasis = [10], rin = rin, rcut=rcut, gamma0 = gamma)
    descriptors[2] = POD(nbody=3, species = [:Hf,:O], pdegree=[6,12,10], nbasis = [12,10], rin = rin, rcut=rcut, gamma0 = gamma)
end

# linear fit to compute POD coefficients
coeff, ce, cf, cef, cefs = linearfit(traindata, descriptors, potentials, Doptions, optim)

# compute unweighted MAE, RMSE, RSQ errors 
energyerrors, forceerrors, stresserrors, eerr, ferr = Optimization.erroranalysis(testdata, descriptors, potentials, Doptions, optim, coeff)    
config, indices = Preprocessing.readconfigdata(testdata[1])     

printerrors("train", energyerrors, "Energy Errors")
printerrors("train", forceerrors, "Force Errors")

Preprocessing.mkfolder("results")
writedlm("results/fitpodcoeff" * string(j) *  ".txt", coeff)
writedlm("results/fitpodtrainerror" * string(j) *  ".txt", [energyerrors forceerrors])    

ind = findall(ferr[1][:] .> 1.5);
lattice = config.lattice[:,ind];
outlat = unique(lattice,dims=2);



