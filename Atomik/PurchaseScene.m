//
//  PurchaseScene.m
//  Atomik
//
//  Created by James on 2/9/14.
//  Copyright (c) 2014 Black Cell. All rights reserved.
//

#import "PurchaseScene.h"

@interface PurchaseScene (Private)
- (void)clampVolumeToSettings;
- (void)renderNavigationButtons;
@end

@implementation PurchaseScene

- (id)init {
	if(self = [super init]) {
        
		// Get the instance of all our of game engine managers.
		_sceneManager = [SceneManager sharedSceneManager];
		_textureManager = [TextureManager sharedTextureManager];
        _imageManager = [ImageManager sharedImageManager];
		_soundManager = [SoundManager sharedSoundManager];
        _gameManager = [GameManager sharedGameManager];
        _networkManager = [NetworkManager sharedNetworkManager];
        _configManager = [ConfigManager sharedConfigManager];
        _progressManager = [ProgressManager sharedProgressManager];
        
        _sceneFadeSpeed = 1.0f;
        sceneAlpha = 1.0f;
		
        [_sceneManager setGlobalAlpha:sceneAlpha];
		
        [_configManager loadPurchaseConfigWithWidth:_width andHeight:_height];
        config = [_configManager getPurchaseConfig];

        background = [[Image alloc] initWithImage:@"Stage_Lite" width:_width height:_height];
        
        control = [[PurchaseControl alloc] init];
        
        font = [[Font alloc] initWithFontImageNamed:@"ObelixPro_Gradient_20" controlFile:@"ObelixPro_Gradient_20" scale:1.0f filter:GL_LINEAR];
        
        // Now we need to load the menu buttons into the image buffers
        buttons = [[NSMutableArray alloc] init];
        for(int i=0; i < [config buttons].count; i++) {
            UIFadeButton *button = (UIFadeButton*)[[config buttons] objectAtIndex:i];
            
            int width = [button bounds].size.width;
            int height = [button bounds].size.height;
            
            Image *image = (Image*)[[Image alloc] initWithImage:[button ID] width:width height:height];
            [_imageManager addImage:image andKey:[button ID]];
            [image release];
        }

        [_soundManager loadMusicWithKey:PURCHASE_LOOP_KEY musicFile:@"Menu_Scene.mp3"];
        [_soundManager setMusicVolume:0.0f];
        
        upperPanelHeight = (_centreY - UPPER_PANEL_LIP_HEIGHT);
        lowerPanelHeight = (_centreY - LOWER_PANEL_LIP_HEIGHT);
        
        upperPanelDelta = 0.0f;
        lowerPanelDelta = 0.0f;
        
        musicVolume = 0.0f;
        effectsVolume = 0.0f;
        
        doorsOpen = NO;
        
        // Angles: 0=Right, 90=Down, 180=Left, 270=Up
        emitter = [[Emitter alloc] initParticleEmitterWithImageNamed:PARTICLE_EMITTER_SPOTLITE
                                                            position:Vector2fMake(_centreX, 290.0f)
                                              sourcePositionVariance:Vector2fMake(160, 160)
                                                               speed:1.0f
                                                       speedVariance:2.0f
                                                    particleLifeSpan:1.0f
                                            particleLifespanVariance:2.0f
                                                               angle:0.0f
                                                       angleVariance:360.0f
                                                             gravity:Vector2fMake(0.0f, -0.0f)
                                                          startColor:Color4fMake(1.00f, 1.00f, 1.00f, 1.00f)
                                                  startColorVariance:Color4fMake(0.00f, 0.00f, 0.00f, 0.00f)
                                                         finishColor:Color4fMake(0.25f, 1.00f, 1.00f, 1.00f)
                                                 finishColorVariance:Color4fMake(0.10f, 0.10f, 0.10f, 0.00f)
                                                        maxParticles:200
                                                        particleSize:10
                                                particleSizeVariance:10
                                                            duration:-1.0f
                                                       blendAdditive:YES];
        
        [emitter setActive:YES];

		nextSceneKey = nil;
		[self setSceneState:kSceneState_TransitionIn];
	}
	return self;
}

- (void)update:(GLfloat)delta {
	
    [emitter update:delta];

	switch (sceneState) {
		case kSceneState_Running:
            
            
			break;
			
		case kSceneState_TransitionOut:
            
            // Adjust the alpha of all the components in the scene.
            [_sceneManager setGlobalAlpha:sceneAlpha];
			
            // Adjust the music volume for the current scene.
            [_soundManager setMusicVolume:musicVolume];
			
			if(!doorsOpen) {
                // If the scene being transitioned to does not exist then transition
                // this scene back in and set the key for the net scene in sequence.
				if(![_sceneManager setCurrentSceneToSceneWithKey:nextSceneKey]) {
                    sceneState = kSceneState_TransitionIn;
				}
                
                [_soundManager stopMusic];
                
			} else {
                // The doors are still open, so we need to initiate close sequence.
                if(upperPanelDelta > 0.0f) {
                    upperPanelDelta -= (UPPER_PANEL_DELTA(upperPanelHeight) * PANEL_OPEN_SPEED_FAST);
                    lowerPanelDelta -= (LOWER_PANEL_DELTA(lowerPanelHeight) * PANEL_OPEN_SPEED_FAST);
                    if(upperPanelDelta < 0.0f) upperPanelDelta = 0.0f;
                    if(lowerPanelDelta < 0.0f) lowerPanelDelta = 0.0f;
                    
                    musicVolume -= FRAME_DELTA;
                    
                } else {
                    doorsOpen = NO;
                }
            }
			
			break;
			
		case kSceneState_TransitionIn:
            
            // Adjust the alpha of all the components in the scene.
            [_sceneManager setGlobalAlpha:sceneAlpha];
            
            // Adjust the music volume for the current scene.
            [_soundManager setMusicVolume:musicVolume];
            
            if(![_soundManager isMusicPlaying]) {
                //[self loadProductsFromServer];
                
                [_soundManager playMusicWithKey:CREDITS_LOOP_KEY timesToRepeat:-1];
            }
            
            // Detect if this is the first time this scene has been executed.
            if(upperPanelDelta < upperPanelHeight) {
                upperPanelDelta += (UPPER_PANEL_DELTA(upperPanelHeight) * PANEL_OPEN_SPEED_FAST);
                lowerPanelDelta += (LOWER_PANEL_DELTA(lowerPanelHeight) * PANEL_OPEN_SPEED_FAST);
                if(upperPanelDelta < 0.0f) upperPanelDelta = 0.0f;
                if(lowerPanelDelta < 0.0f) lowerPanelDelta = 0.0f;
                
                musicVolume += FRAME_DELTA;
                
            } else {
                doorsOpen = YES;
                sceneState = kSceneState_Running;
            }
            
			break;
			
		default:
			break;
	}
	
}

- (void)setSceneState:(uint)state {
	sceneState = state;
	if(sceneState == kSceneState_TransitionOut) {
		sceneAlpha = 1.0f;
	}
	if(sceneState == kSceneState_TransitionIn) {
		sceneAlpha = 1.0f;
	}
}

- (void)transitionToSceneWithKey:(NSString*)key {
    nextSceneKey = key;
    [self setSceneState:kSceneState_TransitionOut];
}

- (void)centreText:(NSString*)text onAxisY:(float)y {
    float x = (_centreX - ([font getWidthForString:text] / 2.0f));
    [font drawStringAt:CGPointMake(x, y) text:text];
}

- (void)updateMenu:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)view {
    UIFadeButton *button = [control getActiveButton];
    if(button != nil) {
        
        // Do we want to navigate to the previous stage?
        if([[button ID] isEqualToString:BACK_BUTTON_KEY]) {
            [self transitionToSceneWithKey:STAGE_SCENE_KEY];
            
        } else if([[button ID] isEqualToString:SAVE_BUTTON_KEY]) {
            [self transitionToSceneWithKey:STAGE_SCENE_KEY];
            
        } else {
            // We need to go off to the app store here
            // Todo, fix this to use a common constant 
            NSString *iTunesLink = @"itms://itunes.apple.com/us/app/apple-store/id813507106?mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        }
    }
}


- (void)renderNavigationButtons {
    // Render the scene navigations buttons
    for(int i=0; i < [config buttons].count; i++) {
        
        float alpha = 1.0f;
        
        UIFadeButton *button = [[config buttons] objectAtIndex:i];
        UIFadeButton *active = [control getActiveButton];
        if(active != nil) {
            if([active ID] == [button ID]) {
                alpha = 0.7f;
            }
        }
        
        Image *image = (Image*)[_imageManager getImageWithKey:[button ID]];
        [image setAlpha:alpha];
        
        [image renderAtPoint:[button position] centerOfImage:YES];
    }
}

- (void)render {
    [background renderAtPoint:CGPointMake(_centreX, _centreY) centerOfImage:YES];
    [emitter renderParticles];
    
    // Render the menu navigation icons for this scene.
    [self renderNavigationButtons];
    
    // Display the scene doors, which should be re-factored to the abstract layer.
    [[_imageManager getImageWithName:UPPER_DOOR_KEY] renderAtPoint:CGPointMake(0, _centreY + upperPanelDelta) centerOfImage:NO];
    [[_imageManager getImageWithName:LOWER_DOOR_KEY] renderAtPoint:CGPointMake(0, 0.0f - lowerPanelDelta) centerOfImage:NO];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)view {
    if(doorsOpen) {
        [control touchesBegan:touches withEvent:event view:view];
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)view {
    if(doorsOpen) {
        [control touchesMoved:touches withEvent:event view:view];
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)view {
    if(doorsOpen) {
        [control touchesEnded:touches withEvent:event view:view];
        
        [self updateMenu:touches withEvent:event view:view];
    }
    [control reset];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event view:(UIView*)view {
    if(doorsOpen) {
        [control touchesCancelled:touches withEvent:event view:view];
    }
    [control reset];
}

- (void)dealloc {
	[super dealloc];
    [control release];
    [font release];
	[background release];
}

@end
