//
//  GLViewController.m
//  OSGIPhone
//
//  Created by BioDigital on 4/10/14.
//
//

#import "GLViewController.h"
#include <iostream>
#include <osgGA/TrackballManipulator>
#include <osgGA/MultiTouchTrackballManipulator>
#include <osg/ShapeDrawable>
//inckude the iphone specific windowing stuff
#include <osgViewer/api/IOS/GraphicsWindowIOS>

@interface GLViewController ()

@end

@implementation GLViewController
class BoxUpdateCallBack : public osg::NodeCallback {
public:
    BoxUpdateCallBack():_angle(0){};
    virtual void operator()(osg::Node* node, osg::NodeVisitor *nv) {
        osg::ref_ptr<osg::MatrixTransform> mTrans = dynamic_cast<osg::MatrixTransform*>(node);
        osg::Matrix rotate, translate;
        rotate.makeRotate(_angle, osg::Vec3(0.0, 0.0, 1.0));
        translate.makeTranslate(osg::Vec3(1,5,1));
        mTrans->setMatrix(translate * rotate);
        _angle += 0.1;
        traverse(node, nv);
    }
    void stop(){};
private:
    double _angle;
    
};

//Get the geo
struct GeometryFinder : public osg::NodeVisitor
{
    osg::ref_ptr<osg::Geometry> _geom;
    GeometryFinder() : osg::NodeVisitor(osg::NodeVisitor::TRAVERSE_ALL_CHILDREN) {}
    void apply(osg::Geode& geode)
    {
        if (_geom.valid())
            return;
        for (unsigned int i = 0; i < geode.getNumDrawables(); i++)
        {
            osg::Geometry* geom = dynamic_cast<osg::Geometry*>(geode.getDrawable(i));
            if (geom) {
                _geom = geom;
                return;
            }
        }
    }
};

//Get the Geometry shape from
osg::ref_ptr<osg::Geometry> getShape(osg::Node *shape) {
    if (shape) {
        GeometryFinder geofinder;
        shape->accept(geofinder);
        return geofinder._geom;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    osg::ref_ptr<osg::GraphicsContext::Traits> traits = new osg::GraphicsContext::Traits;
	CGRect lFrame = [self.glview bounds];
	unsigned int w = lFrame.size.width;
	unsigned int h = lFrame.size.height;
	
	osg::ref_ptr<osg::Referenced> windata = new osgViewer::GraphicsWindowIOS::WindowData(self.glview, osgViewer::GraphicsWindowIOS::WindowData::PORTRAIT_ORIENTATION, [[UIScreen mainScreen] scale]);
	
	// Setup the traits parameters
	traits->x = 0;
	traits->y = 0;
	traits->width = w;
	traits->height = h;
	traits->depth = 16; //keep memory down, default is currently 24
	//traits->alpha = 8;
	//traits->stencil = 8;
	traits->windowDecoration = false;
	traits->doubleBuffer = true;
	traits->sharedContext = 0;
	traits->setInheritedWindowPixelFormat = true;
	
	traits->inheritedWindowData = windata;
    
    
    _sceneRoot = new osg::Group();
    
	// Create the Graphics Context
	osg::ref_ptr<osg::GraphicsContext> graphicsContext = osg::GraphicsContext::createGraphicsContext(traits.get());
	
	osg::ShapeDrawable* drawable = new osg::ShapeDrawable(new osg::Box());
	osg::Geode* geode = new osg::Geode();
	geode->addDrawable(drawable);
    
    
    [self buildScene];
    [self buildAnimatedScene];
    
	
	_viewer = new osgViewer::Viewer();
	
	//Create camera
    osg::ref_ptr<osg::Camera> hudCamera = new osg::Camera();
    hudCamera->setProjectionMatrix(osg::Matrix::ortho2D(0, w, 0, h));
    hudCamera->setReferenceFrame(osg::Transform::ABSOLUTE_RF);
    hudCamera->setViewMatrix(osg::Matrix::identity());
    hudCamera->setViewport(0, 0, w, h);
    hudCamera->setClearMask(GL_DEPTH_BUFFER_BIT);
    hudCamera->setGraphicsContext(graphicsContext);
    hudCamera->setRenderOrder(osg::Camera::POST_RENDER);
	
    _sceneRoot->addChild(hudCamera);
	_viewer->setSceneData(_sceneRoot);
	_viewer->setCameraManipulator(new osgGA::MultiTouchTrackballManipulator);
	
	_viewer->realize();
	
	// get the created view
	osgViewer::GraphicsWindowIOS* window_ios = dynamic_cast<osgViewer::GraphicsWindowIOS*>(graphicsContext.get());
    if (window_ios) {
        int l, t, w, h;
        window_ios->getWindowRectangle(l, t, w, h);
        hudCamera->setProjectionMatrix(osg::Matrix::ortho2D(0, w, 0, t));
    }
    
    [self.glview sendSubviewToBack:(UIView*)window_ios->getView()];
	
	// draw a frame
	_viewer->frame();
    [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(updateScene) userInfo:nil repeats:YES];
    
    UIButton *play = [[UIButton alloc] initWithFrame:CGRectMake(40, 40, 30, 30)];
    [play setTitle:@"Play" forState:UIControlStateNormal];
    [self.view addSubview:play];
    [self.view bringSubviewToFront:play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//
//Timer called function to update our scene and render the viewer
//
- (void)updateScene {
    _viewer->frame();
}

- (void)buildScene {
//    osg::ref_ptr<osg::Node> model = (osgDB::readNodeFile("skydome.ive"));
    osg::Node *pin = osgDB::readNodeFile(osgDB::findDataFile("pin.obj"));
    osg::StateSet *pinstate = pin->getOrCreateStateSet();
    pinstate->setMode(GL_LIGHTING, osg::StateAttribute::OFF);
    
    osg::Geode* geode = new osg::Geode();
    osg::ShapeDrawable* drawable = new osg::ShapeDrawable(new osg::Box(osg::Vec3(0,0,0),2));
    geode->addDrawable(drawable);
    osg::StateSet *ss = geode->getStateSet();
    
    
    osg::Geode* geode2 = new osg::Geode();
    osg::ShapeDrawable* drawable2 = new osg::ShapeDrawable(new osg::Box(osg::Vec3(1,1,1),1));
    drawable2->setColor(osg::Vec4(0.2, 0.4, 0.6, 1.0));
    geode2->addDrawable(drawable2);
    osg::StateSet *stateSetGeode2 = geode2->getOrCreateStateSet();
    stateSetGeode2->setMode(GL_LIGHTING, osg::StateAttribute::OFF);
    
    //Add text
    osg::ref_ptr<osgText::Text> text = new osgText::Text;
    osg::ref_ptr<osg::Geode> textGeode = new osg::Geode();
    osg::StateSet *stateset = textGeode->getOrCreateStateSet();
    stateset->setMode(GL_LIGHTING, osg::StateAttribute::OFF);
    
    
    //Create morph animation
    osgAnimation::Animation *animation = new osgAnimation::Animation();
    osgAnimation::FloatLinearChannel *channel0 = new osgAnimation::FloatLinearChannel;
    channel0->getOrCreateSampler()->getOrCreateKeyframeContainer()->push_back(osgAnimation::FloatKeyframe(0, 0.0));
    channel0->getOrCreateSampler()->getOrCreateKeyframeContainer()->push_back(osgAnimation::FloatKeyframe(1, 1.0));
    channel0->setTargetName("MorphNodeCallback");
    channel0->setName("0");
    
    animation->addChannel(channel0);
    animation->setName("Morph");
    animation->computeDuration();
    animation->setPlayMode(osgAnimation::Animation::PPONG);
    osg::ref_ptr<osgAnimation::BasicAnimationManager> bam = new osgAnimation::BasicAnimationManager();
    bam->registerAnimation(animation);
    
    
    osg::ref_ptr<osg::Geometry> geom0 = new osg::Geometry();
    buildMorph0(*geom0);
    
    osg::ref_ptr<osg::Geometry> geom1 = new osg::Geometry();
    buildMorph1(*geom1);
    
    osgAnimation::MorphGeometry *morph = new osgAnimation::MorphGeometry(*geom0);
    morph->addMorphTarget(geom1.get());
    
    osg::Geode* morphBox = new osg::Geode();
    morphBox->addDrawable(geom0);
    //morphBox->addUpdateCallback(new osgAnimation::UpdateMorph("MorphNodeCallback"));
    
    
    std::string timesFont("arial.ttf");
    text->setFont(timesFont);
    text->setColor(osg::Vec4(0.4, 0.1, 0.9, 1.0));
    text->setPosition(osg::Vec3(0.0, 5.0, 1.0));
    text->setMaximumHeight(10.0);
    text->setMaximumWidth(30.0);
    text->setCharacterSize(5.0, 1.0);
    text->setText("Hello Humans!");
    textGeode->addDrawable(text);
    
    
    //Group the boxes
    osg::ref_ptr<osg::Group> boxGroup = new osg::Group();
    boxGroup->addChild(geode);
    boxGroup->addChild(geode2);
    
    osg::ref_ptr<osg::MatrixTransform> matrixTrans = new osg::MatrixTransform();
    //matrixTrans->setMatrix(translate1);
    matrixTrans->addChild(boxGroup);
    matrixTrans->addUpdateCallback(new BoxUpdateCallBack());
    dynamic_cast<BoxUpdateCallBack*>(matrixTrans->getUpdateCallback())->stop();
    
    //_sceneRoot->addUpdateCallback(bam);
    _sceneRoot->addChild(pin);
    //_sceneRoot->addChild(geode2);
    _sceneRoot->addChild(textGeode);
    //_sceneRoot->removeChild(geode);
    //matrixTrans->addChild(geode2);
    //geode2->getParent(0)->removeChild(geode2);
    _sceneRoot->addChild(matrixTrans.get());
    //_sceneRoot->addChild(morphBox);
    
    //bam->playAnimation(animation);
}

void buildMorph0(osg::Geometry &geo) {
    osg::ref_ptr<osg::Vec3Array> vert0 = new osg::Vec3Array;
    vert0->push_back(osg::Vec3(-1.0, -1.0,  1.0));
    vert0->push_back(osg::Vec3(1.0, -1.0,  1.0));
    vert0->push_back(osg::Vec3(-1.0,  1.0,  1.0));
    vert0->push_back(osg::Vec3(1.0,  1.0,  1.0));
    vert0->push_back(osg::Vec3(-1.0, -1.0, -1.0));
    vert0->push_back(osg::Vec3(1.0, -1.0, -1.0));
    vert0->push_back(osg::Vec3(-1.0,  1.0, -1.0));
    vert0->push_back(osg::Vec3(1.0,  1.0, -1.0));
    geo.setVertexArray(vert0.get());
    
    osg::ref_ptr<osg::IntArray> index = new osg::IntArray;
    
    index->push_back(0);
    index->push_back(1);
    index->push_back(2);
    index->push_back(3);
    index->push_back(7);
    index->push_back(1);
    index->push_back(5);
    index->push_back(4);
    index->push_back(7);
    index->push_back(6);
    index->push_back(2);
    index->push_back(4);
    index->push_back(0);
    index->push_back(1);
    
    osg::Vec4Array *color = new osg::Vec4Array;
    color->push_back(osg::Vec4(0.6, 0.8, 0.5, 1.0));
    geo.setColorArray(color);
    geo.setColorBinding(osg::Geometry::BIND_OVERALL);
    geo.addPrimitiveSet(new osg::DrawArrays(osg::PrimitiveSet::TRIANGLES, 0, 8));
}

void buildMorph1(osg::Geometry &geo) {
    osg::ref_ptr<osg::Vec3Array> vert0 = new osg::Vec3Array;
    vert0->push_back(osg::Vec3(-3.0, -6.0,  1.0));
    vert0->push_back(osg::Vec3(5.0, -1.0,  1.0));
    vert0->push_back(osg::Vec3(-1.0,  1.0,  1.0));
    vert0->push_back(osg::Vec3(-5.0,  2.0,  1.0));
    vert0->push_back(osg::Vec3(-1.0, -1.0, -1.0));
    vert0->push_back(osg::Vec3(1.0, -1.0, -1.0));
    vert0->push_back(osg::Vec3(-1.0,  1.0, -1.0));
    vert0->push_back(osg::Vec3(1.0,  1.0, -1.0));
    geo.setVertexArray(vert0.get());
    
    osg::ref_ptr<osg::IntArray> index = new osg::IntArray;
    
    index->push_back(0);
    index->push_back(1);
    index->push_back(2);
    index->push_back(3);
    index->push_back(7);
    index->push_back(1);
    index->push_back(5);
    index->push_back(4);
    index->push_back(7);
    index->push_back(6);
    index->push_back(2);
    index->push_back(4);
    index->push_back(0);
    index->push_back(1);
    
    osg::Vec4Array *color = new osg::Vec4Array;
    color->push_back(osg::Vec4(0.6, 0.8, 0.5, 1.0));
    geo.setColorArray(color);
    geo.setColorBinding(osg::Geometry::BIND_OVERALL);
    geo.addPrimitiveSet(new osg::DrawArrays(osg::PrimitiveSet::TRIANGLES, 0, 8));
}


//
// Animated scene
osg::Geometry* createSourceGeometry()
{
    osg::ref_ptr<osg::Vec3Array> vertices = new osg::Vec3Array;
    vertices->push_back( osg::Vec3(0.0, 5.0,-2.5) );
    vertices->push_back( osg::Vec3(0.0, 0.0,-2.5) );
    vertices->push_back( osg::Vec3(2.5, 5.0, 0.0) );
    vertices->push_back( osg::Vec3(2.5, 0.0, 0.0) );
    vertices->push_back( osg::Vec3(5.0, 5.0,-2.5) );
    vertices->push_back( osg::Vec3(5.0, 0.0,-2.5) );
    
    osg::ref_ptr<osg::Geometry> geom = new osg::Geometry;
    geom->setVertexArray( vertices.get() );
    geom->addPrimitiveSet( new osg::DrawArrays(GL_QUAD_STRIP,0,6) );
    
    osgUtil::SmoothingVisitor smv;
    smv.smooth( *geom );
    return geom.release();
}

osg::Geometry* createTargetGeometry()
{
    osg::ref_ptr<osg::Vec3Array> vertices = new osg::Vec3Array;
    vertices->push_back( osg::Vec3(0.0, 5.0, 1.0) );
    vertices->push_back( osg::Vec3(0.0, 0.0, 1.0) );
    vertices->push_back( osg::Vec3(2.5, 5.0,-1.0) );
    vertices->push_back( osg::Vec3(2.5, 0.0,-1.0) );
    vertices->push_back( osg::Vec3(5.0, 5.0, 1.0) );
    vertices->push_back( osg::Vec3(5.0, 0.0, 1.0) );
    vertices->push_back( osg::Vec3(5.0, 0.0, 15.0) );
    
    osg::ref_ptr<osg::Geometry> geom = new osg::Geometry;
    geom->setVertexArray( vertices.get() );
    geom->addPrimitiveSet( new osg::DrawArrays(GL_QUAD_STRIP,0,7) );
    
    osgUtil::SmoothingVisitor smv;
    smv.smooth( *geom );
    return geom.release();
}

void createMorphKeyframes( osgAnimation::FloatKeyframeContainer* container )
{
    container->push_back( osgAnimation::FloatKeyframe(0.0, 0.0) );
    container->push_back( osgAnimation::FloatKeyframe(0.5, 0.25) );
    container->push_back( osgAnimation::FloatKeyframe(1.0, 0.5) );
    container->push_back( osgAnimation::FloatKeyframe(1.5, 0.75) );
    container->push_back( osgAnimation::FloatKeyframe(2.0, 1.0) );
}

- (void)buildAnimatedScene
{
    osg::ref_ptr<osgAnimation::FloatLinearChannel> channel = new osgAnimation::FloatLinearChannel;
    channel->setName( "0" );
    channel->setTargetName( "MorphCallback" );
    createMorphKeyframes( channel->getOrCreateSampler()->getOrCreateKeyframeContainer() );
    osg::ref_ptr<osgAnimation::Animation> anim = new osgAnimation::Animation;
    anim->setPlayMode(osgAnimation::Animation::PPONG);
    anim->addChannel( channel.get() );
    
    osg::ref_ptr<osgAnimation::BasicAnimationManager> mng = new osgAnimation::BasicAnimationManager;
    mng->registerAnimation( anim.get() );
    
    osg::ref_ptr<osgAnimation::MorphGeometry> morph = new osgAnimation::MorphGeometry( *createSourceGeometry() );
    morph->addMorphTarget( createTargetGeometry() );
    
    osg::ref_ptr<osg::Geode> geode = new osg::Geode;
    geode->addDrawable( morph.get() );
    geode->setDataVariance(osg::Geometry::DYNAMIC);
    geode->setUpdateCallback( new osgAnimation::UpdateMorph("MorphCallback") );
    
    _sceneRoot->addChild( geode.get() );
    _sceneRoot->setUpdateCallback( mng );
    
    mng->playAnimation( anim.get() );
    
    //osgViewer::Viewer viewer;
    //viewer.setSceneData( _sceneRoot.get() );
}

USE_GRAPICSWINDOW_IMPLEMENTATION(IOS)
USE_OSGPLUGIN(obj)

- (void)dealloc {
    [_glview release];
    [super dealloc];
}
@end
