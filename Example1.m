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

model.label('example1.mph');

%% Set up parameters
model.param.set('L', '9[cm]', 'Length of the busbar');
model.param.set('rad_1', '6[mm]', 'Radius of the fillet');
model.param.set('tbb', '5[mm]', 'Thickness');
model.param.set('wbb', '5[cm]', 'Width');
model.param.set('mh', '6[mm]', 'Maximum element size');
model.param.set('htc', '5[W/m^2/K]', 'Heat transfer coefficient');
model.param.set('Vtot', '20[mV]', 'Applied electric potential');

%% Set up Geometry 
geom1 = model.geom.create('geom1', 3);
wp1 = geom1.feature.create('wp1', 'WorkPlane');
wp1.set('quickplane', 'xz');

r1 = wp1.geom.feature.create('r1', 'Rectangle');
r1.set('size', {'L+2*tbb' '0.1'});

r2 = wp1.geom.feature.create('r2', 'Rectangle');
r2.set('size', {'L+tbb' '0.1-tbb'});
r2.set('pos', {'0' 'tbb'});

dif = wp1.geom.feature.create('dif', 'Difference');
dif.selection('input').set({'r1'});
dif.selection('input2').set({'r2'});

fil1 = wp1.geom.feature.create('fil1', 'Fillet');
fil1.selection('point').set('dif(1)', 3);
fil1.set('radius', 'tbb');

fil2 = wp1.geom.feature.create('fil2', 'Fillet');
fil2.selection('point').set('fil1(1)', 6);
fil2.set('radius', '2*tbb');

ext1 = geom1.feature.create('ext1', 'Extrude');
ext1.selection('input').set({'wp1'});
ext1.set('distance', {'wbb'});

wp2 = geom1.feature.create('wp2', 'WorkPlane');
wp2.set('planetype', 'faceparallel');
wp2.selection('face').set('ext1(1)', 8);

c1 = wp2.geom.feature.create('c1', 'Circle');
c1.set('r', 'rad_1');

ext2 = geom1.feature.create('ext2', 'Extrude');
ext2.selection('input').set({'wp2'});
ext2.set('distance', {'-2*tbb'});

wp3 = geom1.feature.create('wp3', 'WorkPlane');
wp3.set('planetype', 'faceparallel');
wp3.selection('face').set('ext1(1)', 4);

c2 = wp3.geom.feature.create('c2', 'Circle');
c2.set('r', 'rad_1');
c2.set('pos', {'-L/2+1.5e-2' '-wbb/4'});

copy = wp3.geom.feature.create('copy', 'Copy');
copy.selection('input').set({'c2'});
copy.set('disply', 'wbb/2');

ext3 = geom1.feature.create('ext3', 'Extrude');
ext3.selection('input').set({'wp3.c2' 'wp3.copy'});
ext3.set('distance', {'-2*tbb'});

geom1.run;
figure, mphgeom(model);

%% Set up Material
sel1 = model.selection.create('sel1');
sel1.set([2 3 4 5 6 7]);
sel1.label('Ti bolts');

figure, mphviewselection(model,'sel1');

mat1 = model.material.create('mat1');
mat1.materialModel('def').set('electricconductivity', {'5.998e7[S/m]'});
mat1.materialModel('def').set('heatcapacity', '385[J/(kg*K)]');
mat1.materialModel('def').set('relpermittivity', {'1'});
mat1.materialModel('def').set('density', '8700[kg/m^3]');
mat1.materialModel('def').set('thermalconductivity', {'400[W/(m*K)]'});

mat1.label('Copper');

mat2 = model.material.create('mat2');
mat2.materialModel('def').set('electricconductivity', {'7.407e5[S/m]'});
mat2.materialModel('def').set('heatcapacity', '710[J/(kg*K)]');
mat2.materialModel('def').set('relpermittivity', {'1'});
mat2.materialModel('def').set('density', '4940[kg/m^3]');
mat2.materialModel('def').set('thermalconductivity', {'7.5[W/(m*K)]'});
mat2.label('Titanium');

mat2.selection.named('sel1');

%% Set up Physics
ht = model.physics.create('ht', 'HeatTransfer', 'geom1');

hf1 = ht.feature.create('hf1', 'HeatFluxBoundary', 2);

hf1.set('HeatFluxType', 'InwardHeatFlux');
hf1.selection.set([1:7 9:14 16:42]);
hf1.set('h', 'htc');

% figrue, mphgeom(model,'geom1','facemode','off','facelabels','on')

ec = model.physics.create('ec', 'ConductiveMedia', 'geom1');

pot1 = ec.feature.create('pot1', 'ElectricPotential', 2);
pot1.selection.set(43);
pot1.set('V0', 'Vtot');

gnd1 = ec.feature.create('gnd1', 'Ground', 2);
gnd1.selection.set([8 15]);

emh = model.multiphysics.create('emh','ElectromagneticHeatSource',...
    'geom1',3);
emh.selection.all;

emh.set('EMHeat_physics', 'ec');
emh.set('Heat_physics', 'ht');

%% Set up Mesh
mesh = model.mesh.create('mesh', 'geom1');

size = mesh.feature('size');
size.set('hmax', 'mh');
size.set('hmin', 'mh-mh/3');
size.set('hcurve', '0.2');

ftet = mesh.feature.create('ftet', 'FreeTet');

mesh.run;

figure, mphmesh(model);

%% Set up Study
std = model.study.create('std');
stat = std.feature.create('stat', 'Stationary');

std.run;

%% Extract Result
pg = model.result.create('pg', 'PlotGroup3D');

surf = pg.feature.create('surf', 'Surface');
surf.set('expr', 'T');
surf.set('rangecoloractive', 'on');
surf.set('rangecolormin', '322.6');
surf.set('rangecolormax', '323.3');

figure, mphplot(model,'pg','rangenum',1)
% ModelUtil.disconnect;
