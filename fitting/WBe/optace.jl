cdir = pwd(); ii = findlast("MLP", cdir); MLPpath = cdir[1:ii[end]] * "/";    
include(MLPpath * "src/setup.jl");

push!(LOAD_PATH, MLPpath * "src/ACEpot");
using ACEpot
using DelimitedFiles

# path to the database 
datapath = "../../data/WBe/JSON/"
dataformat = "json"
fileextension = "json"
atomspecies = ["W", "Be"];

# folders in the datapath 
folders = ["001FreeSurf", "010FreeSurf", "100FreeSurf", "Defect_BCrowd",
            "Defect_BOct", "Defect_BSplit", "Defect_BTetra", "Defect_Crowd", "Defect_Oct",
            "Defect_Tet", "Defect_Vacancy", "DFTMD_1000K", "DFTMD_300K", "Elast_BCC_Shear", 
            "Elast_BCC_Vol","Elast_FCC_Shear", "Elast_FCC_Vol", "Elast_HCP_Shear", "Elast_HCP_Vol",
            "EOS_BCC","EOS_FCC", "EOS_HCP", "StackFaults","Liquids","DFT_MD_1000K", "DFT_MD_300K", 
            "ElasticDeform_Shear","ElasticDeform_Vol", "EOS", "WSurface_BeAdhesion", 
            "BCC_ForceLib_W110", "BCC_ForceLib_W111", "BCC_ForceLib_WOct", "BCC_ForceLib_WTet",
            "dislocation_quadrupole", "Disordered_Struc", "Divacancy", "EOS_Data", "gamma_surface",
            "gamma_surface_vacancy","md_bulk","slice_sample","surface","vacancy"];

n = length(folders)
weightinner = zeros(n,3)
weightinner[:,1] .= 100.0
weightinner[:,2] .= 1.0

# folders = folders[29:30]
# weightinner = weightinner[29:30,:]

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
for i = 1:length(folders)
    traindata[i] = adddata(datapath * folders[i], dataformat, fileextension, 
                percentage, randomize, atomspecies, weightinner[i,:], translationvector, 
                rotationmatrix, transposelattice)
end

# Descriptors optional parameters
Doptions = DescriptorsOptions(pbc = [1, 1, 1], normalizeenergy=true, normalizestress=true)

# loss function style must be: "energy", "force", "energyforce", "energyforcestress"
lossfunc = "energyforce"

# use least-square method
method = "lsq" 

# cut-off radius
rcut = 5.0

# inner radius 
rin = 0.9

# bounds for cut-off radius to be optimized
rcutrange = [3.8, 5.0]

# bounds for inner radius to be optimized
rinrange = [0.3, 1.5]

# define range for nonlinear parameters to be optimized
etarange =  hcat(rcutrange, rinrange)'

# number of interpolation points for each nonlinear parameters 
N = [7,7]
etaspace = [etarange N]

# optimization parameters
eta = [rcut, 1.0]; 
kappa = [0];  
optim = setoptim(lossfunc, method, eta, kappa, weightouter, etaspace)

for j = 0:0
    display(j)

    # ACE descriptors
    if j == 0
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=3, pdegree=6, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=2.0, csp=1.75)
    elseif j == 1
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=4, pdegree=8, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.75, csp=1.5)
    elseif j==2
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=2, pdegree=3, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.5, csp=1.5)
        descriptors[2] = ACEpot.ACEparams(species = [:W,:Be], nbody=4, pdegree=10, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.25, csp=1.5)
    elseif j==3 
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=2, pdegree=3, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.5, csp=1.5)
        descriptors[2] = ACEpot.ACEparams(species = [:W,:Be], nbody=4, pdegree=12, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.5, csp=1.5)
    elseif j==4
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=2, pdegree=12, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.5, csp=1.5)
        descriptors[2] = ACEpot.ACEparams(species = [:W,:Be], nbody=4, pdegree=12, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.35, csp=1.25)
    elseif j==5           
        descriptors[1] = ACEpot.ACEparams(species = [:W,:Be], nbody=4, pdegree=13, r0=ACEpot.rnn(:Be), rcut=rcut, rin=rin, wL=1.15, csp=1.25)
    end
    
    # optimize the ace potential 
    opteta, coeff, fmin, iter, polycoeff = optimize(traindata, traindata, descriptors, potentials, Doptions, optim)

    # compute unweighted MAE, RMSE, RSQ errors 
    energyerrors, forceerrors, stresserrors = validate(traindata, descriptors, potentials, Doptions, optim, coeff)    

    printerrors(folders, energyerrors, "Energy Errors")
    printerrors(folders, forceerrors, "Force Errors")

    Preprocessing.mkfolder("results")
    writedlm("results/optacecoeff" * string(j) *  ".txt", coeff)
    writedlm("results/optacepolycoeff" * string(j) *  ".txt", polycoeff)
    writedlm("results/optacetrainerror" * string(j) *  ".txt", [energyerrors forceerrors])    
    writedlm("results/optaceeta" * string(j) *  ".txt", opteta)
end

