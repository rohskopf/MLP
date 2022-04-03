cdir = pwd(); ii = findlast("MLP", cdir); MLPpath = cdir[1:ii[end]] * "/";    
include(MLPpath * "src/setup.jl");

using DelimitedFiles

# path to the database 
datapath = "../../data/"
folders = ["GaN"]
dataformat = "extxyz"
fileextension = "exyz"
atomspecies = ["Ga", "N"];

n = length(folders)
weightinner = zeros(n,3)
weightinner[:,1] .= 100.0
weightinner[:,2] .= 1.0

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
traindata[1] = adddata(datapath * folders[1], dataformat, fileextension, 
            percentage, randomize, atomspecies, weightinner[1,:], translationvector, 
            rotationmatrix, transposelattice)

# Descriptors optional parameters
Doptions = DescriptorsOptions(pbc = [1, 1, 1], normalizeenergy=true, normalizestress=true)

# loss function style must be: "energy", "force", "energyforce", "energyforcestress"
lossfunc = "energyforce"

# use least-square method
method = "lsq" 

# bounds for cut-off radius to be optimized
rcutrange = [3.5, 5.0]

# define range for nonlinear parameters to be optimized
etarange =  reshape(rcutrange,(1,2))

# number of interpolation points for each nonlinear parameters 
N = [7]
etaspace = [etarange N]

# cut-off radius
rcut = 5.0

# inner radius 
rin = 0.5

# Bessel scaling parameters
gamma = [0.0, 2, 4]

# optimization parameters
eta = [rcut]; 
kappa = [0];  
optim = setoptim(lossfunc, method, eta, kappa, weightouter, etaspace)

for j = 3:3
    display(j)
    # POD Descriptors
    if j == 0
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[2,4], nbasis = [2], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[2,2,2], nbasis = [1, 2], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    elseif j == 1
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[2,6], nbasis = [3], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[2,4,3], nbasis = [3, 3], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    elseif j==2
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[3,6], nbasis = [6], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[3,6,4], nbasis = [5, 4], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    elseif j==3 
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[4,6], nbasis = [8], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[4,6,5], nbasis = [8, 5], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    elseif j==4
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[6,8], nbasis = [11], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[6,8,7], nbasis = [10, 7], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    elseif j==5           
        descriptors[1] = POD(nbody=2, species = [:Ga,:N], pdegree=[6,12], nbasis = [10], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
        descriptors[2] = POD(nbody=3, species = [:Ga,:N], pdegree=[6,12,10], nbasis = [12,10], rin = rin, rcut=rcut, gamma0 = gamma, hybrid23=true, projectiontol=1e-8)
    end

    # optimize the pod potential 
    opteta, coeff, fmin, iter, polycoeff, etapts, lossvalues, energyerrors, forceerrors = optimize(traindata, traindata, descriptors, potentials, Doptions, optim)

    e1 = [energyerrors[:,1] energyerrors[:,2] 0*energyerrors[:,1]]
    e2 = [forceerrors[:,1] forceerrors[:,2] 0*forceerrors[:,1]]
    printerrors(["train"], e1, "Energy Errors")
    printerrors(["train"], e2, "Force Errors")
        
    Preprocessing.mkfolder("results")
    writedlm("results/optpod23coeff" * string(j) *  ".txt", coeff)
    writedlm("results/optpod23polycoeff" * string(j) *  ".txt", polycoeff)
    writedlm("results/optpod23trainerror" * string(j) *  ".txt", [energyerrors forceerrors])    
    #writedlm("results/optpod23testerror" * string(j) *  ".txt", [energytesterrors forcetesterrors])    
    writedlm("results/optpod23eta" * string(j) *  ".txt", opteta)
end

