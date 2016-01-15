%% 
% Author: Zhang Chuheng (zhangchuheng123@live.com)
% Date: Jan. 15, 2016

%% Setup the Model
ModelUtil.clear;
list = ModelUtil.tags;
if (numel(list) == 0)
    model = ModelUtil.create('Model');
else
    model = ModelUtil.model(string(list(1)));
end

model.label('example2.mph');

%% Set up parameters
model.param.set('wl','1.15[um]','Wavelength');
model.param.set('f0','c_const/wl','Frequancy');
model.param.set('a','3[um]','Side of waveguide cross-section');
model.param.set('d','3[um]','Distance between the waveguildes');
model.param.set('len','2.1[mm]','waveguide length');
model.param.set('width','6*a','Width of calculation domain');
model.param.set('heigth','4*a','Height of calculation domain');
model.param.set('ncl','3.47','Refractive index of GaAs');
model.param.set('dn','0.005','Refractive index increase in waveguide core');
model.param.set('nco','ncl+dn','Refractive index in waveguide core');

%% Set up Geometry 
comp1 = model.modelNode.create('comp1');
geom1 = model.geom.create('geom1', 3);

block1 = geom1.create('block1','Block');
block1.set('size',{'len','width','heigth'});
block1.set('pos',{'0','-0.5*width','0'});
block1.label('Block 1');

block2 = geom1.create('block2','Block');
block2.set('size',{'len','a','a'});
block2.set('pos',{'0','-0.5*d-a','0.5*(heigth-a)'});
block2.label('Block 2');

block3 = geom1.create('block3','Block');
block3.set('size',{'len','a','a'});
block3.set('pos',{'0','0.5*d','0.5*(heigth-a)'});

geom1.run;
figure, mphgeom(model);

%% Set up Material
mat1 = model.material.create('mat1', 'Common', 'comp1');
mat1.selection.set([1]);
mat1.propertyGroup.create('RefractiveIndex', 'Refractive index');
mat1.propertyGroup('RefractiveIndex').set('n', {'ncl'});

mat2 = model.material.create('mat2', 'Common', 'comp1');
mat2.selection.set([2 3]);
mat2.propertyGroup.create('RefractiveIndex', 'Refractive index');
mat2.propertyGroup('RefractiveIndex').set('n', {'nco'});

%% Set up Physics
ewbe = model.physics.create('ewbe', 'ElectromagneticWavesBeamEnvelopes', 'geom1');
ewbe.prop('WaveVector').set('dirCount', 'UniDirectionality');
ewbe.prop('WaveVector').set('k1', {'ewbe.beta_1' '0' '0'});

port1 = ewbe.feature.create('port1', 'Port', 2);
port1.selection.set([1,5,10]);
port1.set('PortType', 'Numeric');
port1.set('PortExcitation', 'on');
ewbe.feature.duplicate('port2', 'port1');

port3 = ewbe.feature.create('port3', 'Port', 2);
port3.selection.set([16,17,18]);
port3.set('PortType', 'Numeric');
ewbe.feature.duplicate('port4', 'port3');

%% Set up Mesh
mesh1 = model.mesh.create('mesh1', 'geom1');
ftri1 = mesh1.feature.create('ftri1', 'FreeTri');
ftri1.selection.set([1 5 10]);
size1 = ftri1.create('size1', 'Size');
size1.set('custom', 'on');
size1.set('hmaxactive', 'on');
size1.set('hmax', 'wl');
size1.set('hminactive', 'on');
size1.set('hmin', 'wl/2');

swe1 = model.mesh('mesh1').feature.create('swe1', 'Sweep');

mesh1.feature('size').set('custom', 'on');
mesh1.feature('size').set('hmax', 'len/20');
mesh1.run;

figure, mphmesh(model);

%% Set up study
std1 = model.study.create('std1');
bma = model.study('std1').create('bma', 'BoundaryModeAnalysis');
bma.set('notsolnum', 'auto');
bma.set('showGeometricNonlinearity', 'on');
bma.set('solnum', 'auto');
bma.set('neigs', '4');
bma.set('shift', 'nco');
bma.set('modeFreq', 'f0');
bma.activate('ewbe', true);

std1.run;

%% Draw the Result
pg1 = model.result.create('pg1', 'PlotGroup3D');
pg1.create('surf1', 'Surface');
pg1.feature('surf1').set('expr', 'ewbe.tEbm1z');
pg1.set('looplevel', {'4'});
pg1.run;
figure, mphplot(model,'pg1','rangenum',1);
