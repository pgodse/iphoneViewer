//
//  GLViewController.h
//  OSGIPhone
//
//  Created by BioDigital on 4/10/14.
//
//
#include <osgDB/ReadFile>
#include <osg/MatrixTransform>
#include <osg/CameraNode>
#include <osgText/Text>
#include <osgViewer/Viewer>
#include <osgAnimation/BasicAnimationManager>
#include <osgAnimation/Animation>
#include <osgAnimation/MorphGeometry>
#include <osgDB/FileUtils>
#include <osgUtil/SmoothingVisitor>

#import <UIKit/UIKit.h>

@interface GLViewController : UIViewController {
    osg::ref_ptr<osgViewer::Viewer> _viewer;
    osg::ref_ptr<osg::MatrixTransform> _root;
    osg::ref_ptr<osg::Group> _sceneRoot;
}
@property (retain, nonatomic) IBOutlet UIView *glview;
@end
