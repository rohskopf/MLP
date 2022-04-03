cdir = pwd(); ii = findlast("MLP", cdir); MLPpath = cdir[1:ii[end]] * "/";    
include(MLPpath * "src/setup.jl");

using DelimitedFiles

# path to the database 
datapath = "../../data/aHfO2/"
dataformat = "extxyz"
fileextension = "xyz"
atomspecies = ["Hf", "O"];

# weights for energies, forces, and stresses in the linear fit
weightinner=[100  1  0.0]

# weights for energies, forces, and stresses in the outer nonlinear optimization
weightouter = [0.1, 0.9, 0.0]

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
rcut = 4.689977113821321

# inner radius 
rin = 1.0

# optimization parameters
optim = setoptim(lossfunc, method)

wj = [1.0, 0.9590493408]
radelem = [0.5, 0.417932464]
bzeroflag = 1
chemflag = 1

# SNAP descriptors
descriptors[1] = SNAPparams(species = [:Hf,:O], twojmax = 6, rcutfac = rcut, rfac0 = 0.99363, 
    elemradius = radelem, elemweight = wj, bzeroflag = bzeroflag, chemflag = chemflag)

# Descriptors optional parameters
Doptions = DescriptorsOptions(pbc = [1, 1, 1], normalizeenergy=true, normalizestress=true)

# linear fit to compute SNAP coefficients
coeff, ce, cf, cef, cefs, emae, fmae, smae,~ = linearfit(traindata, descriptors, potentials, Doptions, optim)

print("SNAP Coeffficients: "), show(stdout, "text/plain", coeff)

# # compute unweighted MAE, RMSE, RSQ erroxrs 
energyerrors, forceerrors, stresserrors = validate(testdata, descriptors, potentials, Doptions, optim, coeff)    


# printerrors(folders, energyerrors, "Energy Errors")
# printerrors(folders, forceerrors, "Force Errors")
# printerrors(folders, stresserrors, "Stress Errors")

# err = [energyerrors forceerrors stresserrors]
# using DelimitedFiles
# Preprocessing.mkfolder("results")
# writedlm("results/fitsnapcoeff.txt", coeff)
# writedlm("results/fitsnaperror.txt", err)

# ----------------------------------------------------------------------------------------
# Energy Errors |          MAE          |          RMSE          |          RSQ          |
# ----------------------------------------------------------------------------------------
# ALL           |   0.07044207657701    |    0.21603314997155    |    0.99812010420952   |
# Displaced_A15 |   0.00096552143837    |    0.00111604188449    |    0.54713143273288   |
# Displaced_BCC |   0.00265790526799    |    0.00282445652492    |    0.99558694447092   |
# Displaced_FCC |   0.00062281398597    |    0.00070621825523    |    0.97482658887872   |
# Elastic_BCC   |   0.01609666719843    |    0.01611409810408    |    0.94536142997231   |
# Elastic_FCC   |   0.00236015882463    |    0.00283113393722    |    0.99731108251481   |
# GSF_110       |   0.00273706745771    |    0.00327819622044    |    0.96961211605756   |
# GSF_112       |   0.00493895723907    |    0.00543788060718    |    0.95943391379761   |
# Liquid        |   0.00202413959425    |    0.00220367987714    |    0.99954957466195   |
# Surface       |   0.00986241413964    |    0.01286642045895    |    0.99206605756607   |
# Volume_A15    |   0.15845142823669    |    0.20402247466747    |    0.99923461069253   |
# Volume_BCC    |   0.24054293169245    |    0.34857690690444    |    0.99932441035003   |
# Volume_FCC    |   0.43992415339314    |    0.65036051729788    |    0.99528215114935   |
# ----------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------
# Force Errors  |          MAE          |          RMSE          |          RSQ          |
# ----------------------------------------------------------------------------------------
# ALL           |   0.07382175918033    |    0.13473293245264    |    0.98985401189508   |
# Displaced_A15 |   0.10121880694163    |    0.13144958315829    |    0.94699246994167   |
# Displaced_BCC |   0.11558686617518    |    0.14717456426298    |    0.99060566246513   |
# Displaced_FCC |   0.04485641678835    |    0.05799790562769    |    0.98730139228410   |
# Elastic_BCC   |   0.05124398995294    |    0.06281587640833    |    0.62885074654137   |
# Elastic_FCC   |   0.03767913962690    |    0.04833932543656    |    0.79876767281188   |
# GSF_110       |   0.02331765506779    |    0.04143778578021    |    0.99935586576560   |
# GSF_112       |   0.06227573920557    |    0.09595691088125    |    0.99759093141190   |
# Liquid        |   0.29368616066726    |    0.38087413462762    |    0.96762323524226   |
# Surface       |   0.04715202191799    |    0.10329820204475    |    0.99705018659741   |
# Volume_A15    |   3.46844637110477    |    8.17503109246182    |    0.47346230209265   |
# Volume_BCC    |   2.26883249123272    |    4.74575523467808    |    -2.5290229329517   |
# Volume_FCC    |   1.49145134984300    |    3.37372286466239    |    0.07729394577249   |
# ----------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------
# Stress Errors |          MAE          |          RMSE          |          RSQ          |
# ----------------------------------------------------------------------------------------
# ALL           |   35971.9793128237    |    195191.138554860    |    0.98421362798808   |
# Displaced_A15 |   22461.9928376593    |    31109.3032729486    |    0.99670734388147   |
# Displaced_BCC |   3156.48504229259    |    4399.91212860888    |    0.99994088314579   |
# Displaced_FCC |   11193.8066343422    |    15619.4228192125    |    0.99912377097448   |
# Elastic_BCC   |   280.397837618711    |    396.387323061027    |    0.99999951872136   |
# Elastic_FCC   |   21366.3276195083    |    29271.1138024509    |    0.99696441213386   |
# GSF_110       |   1582.59625565322    |    2337.94276204977    |    0.99993757303705   |
# GSF_112       |   2156.25006603071    |    3080.77851292823    |    0.99987925470715   |
# Liquid        |   39240.6700104592    |    54157.2641612818    |    0.98826937704021   |
# Surface       |   2273.06425492121    |    4022.91528154733    |    0.99980384280603   |
# Volume_A15    |   88790.3570675373    |    298468.446977544    |    0.96695967433505   |
# Volume_BCC    |   152032.930937683    |    452922.949353301    |    0.99110567462576   |
# Volume_FCC    |   144824.356245268    |    466410.633437398    |    0.96121748046692   |
# ----------------------------------------------------------------------------------------

