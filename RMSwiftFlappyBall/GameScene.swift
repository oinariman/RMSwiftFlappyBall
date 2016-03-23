//
//  GameScene.swift
//  RMSwiftFlappyBall
//
//  Created by Ryosuke Mihara on 2014/06/04.
//  Copyright (c) 2014年 Ryosuke Mihara. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    enum Phase {
        case GetReady, Game, GameOver, Medal
    }
    
    // colors
    let ballColor = UIColor(red: 1.0, green: 0.26, blue: 0.45, alpha: 1.0)
    let wallColor = UIColor.cyanColor()
    let fontColor = UIColor(red: 1.0, green: 0.26, blue: 0.45, alpha: 1.0)
    let fontName = "AmericanTypewriter-Bold"

    // floor
    let kFloorHeight : CGFloat = 84.0
    
    // ball
    let kBallWidth : CGFloat = 29.0
    let kGravity : CGFloat = -9.8 * 0.9
    let kFlappingVelocityY : CGFloat = 390.0
    
    // wall
    let kWallWidth : CGFloat = 50.0
    let kWallHeightUnit : CGFloat = 480.0 / 13.0
    let kHoleHeight : CGFloat = 3.0
    let kUpperWallHeightMin : UInt32 = 2
    let kUpperWallHeightMax : UInt32 = 8
    let kIntervalBetweenWalls : NSTimeInterval = 1.4
    let kWallSpeed : CGFloat = 320.0 / 3.0
    
    var phase = Phase.GetReady
    var points = 0
    var timeForWallGoThroughBall : NSTimeInterval = 0.0
    var heightDiff : CGFloat = 0.0
    
    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.whiteColor()
        timeForWallGoThroughBall = NSTimeInterval(size.width / kWallSpeed * 0.75)
        heightDiff = (size.height - 480.0) * 0.5
        getReady()
    }
    
    func flap() {
        if let physicsBody = childNodeWithName("🐦")?.physicsBody {
            runAction(SKAction.playSoundFileNamed("flap.caf", waitForCompletion: false))
            physicsBody.velocity.dy = kFlappingVelocityY
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        switch phase {
        case .Game:
            flap()
            
        case .Medal:
            if childNodeWithName("cover") == nil {
                goBackToGetReady()
            }
            
        case .GetReady:
            startGame()
            flap()
            
        default:
            print("🍣")
            
        }
    }
    
    // MARK: - Phase
    
    /**
     * Moves to "Get Ready" phase.
     */
    func getReady()
    {
        putBall()
        if let 🐦 = childNodeWithName("🐦") {
            🐦.physicsBody?.affectedByGravity = false
            
            
            let up = SKAction.moveBy(CGVectorMake(0.0, kBallWidth), duration: 0.4)
            up.timingMode = .EaseOut
            let down = SKAction.moveBy(CGVectorMake(0.0, -kBallWidth), duration: 0.35)
            down.timingMode = .EaseIn
            🐦.runAction(SKAction.repeatActionForever(SKAction.sequence([up, down])))
        }
        
        putFloor()
        
        phase = Phase.GetReady
    }
    
    /**
    *  Moves to game over phase.
    */
    func gameOver()
    {
        removeAllActions()
        children.forEach { $0.removeAllActions() }
        putGameOverLabel()
        phase = Phase.GameOver
    }
    
    /**
    *  Starts game.
    */
    func startGame()
    {
        phase = Phase.Game
        childNodeWithName("🐦")?.removeFromParent()
        
        physicsWorld.gravity = CGVectorMake(0.0, kGravity)
        physicsWorld.contactDelegate = self
        
        putBall()
        putWallsPeriodically()
        putPointsLabel()
        
        points = 0
    }
    
    /**
    *  Fades out and then moves to "Get Ready" phase.
    */
    func goBackToGetReady()
    {
        let cover = SKSpriteNode(color: UIColor.blackColor(), size: size)
        cover.alpha = 0.0
        cover.name = "cover"
        cover.position = CGPointMake(size.width/2.0, size.height/2.0)
        cover.zPosition = 100000
        addChild(cover)
        
        cover.runAction(SKAction.sequence([
            SKAction.fadeInWithDuration(0.3),
            SKAction.runBlock({
                self.removeChildrenInArray(self.children)
                self.getReady() }),
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()
            ]))
    }
    
    // MARK: - 1. Ball
    
    func ballImage(size: CGSize, color: UIColor) ->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillEllipseInRect(context, CGRectMake(0.5, 0.5, size.width - 1.0, size.height - 1.0))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func putBall()
    {
        let 🐦 = SKSpriteNode(texture: SKTexture(image: ballImage(CGSizeMake(kBallWidth, kBallWidth), color: ballColor)))
        🐦.position = CGPointMake(size.width / 4.0, size.height / 2.0)
        🐦.name = "🐦"
        
        let body = SKPhysicsBody(circleOfRadius: kBallWidth / 2.0)
        🐦.physicsBody = body
        
        addChild(🐦)
    }
    
    // MARK: - 2. Floor
    
    func floorImageWithSize(size: CGSize) -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.mainScreen().scale)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0)
        CGContextSetRGBFillColor(context, 0.8, 0.8, 0.8, 1.0)
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size))
        
        CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 1.0)
        CGContextSetLineDash(context, 0, [16.0, 16.0], 2)
        CGContextSetLineWidth(context, 2.0)
        for i in 0..<3 {
            CGContextMoveToPoint(context, 0.0, CGFloat(i) * 2.0)
            CGContextAddLineToPoint(context, size.width, CGFloat(i) * 2.0)
        }
        CGContextStrokePath(context);
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    /**
    *  Puts floor.
    */
    func putFloor()
    {
        let floorSize = CGSizeMake(size.width * 2.0, kFloorHeight + heightDiff)
        
        let floor = SKSpriteNode(texture:SKTexture(image:floorImageWithSize(floorSize)))
        floor.size = floorSize
        floor.position = CGPointMake(size.width, floorSize.height * 0.5)
        floor.name = "floor"
        floor.zPosition = 4000
        
        let body = SKPhysicsBody(rectangleOfSize:floorSize)
        body.affectedByGravity = false
        body.dynamic = false
        body.contactTestBitMask = 1
        body.linearDamping = 0.0
        floor.physicsBody = body
        
        let sequence = SKAction.sequence([
            SKAction.moveToX(0.0, duration:NSTimeInterval(size.width / kWallSpeed)),
            SKAction.moveToX(size.width, duration:0.0)])
        let action = SKAction.repeatActionForever(sequence)
        floor.runAction(action)
        
        addChild(floor)
    }
    
    // MARK: - 3. Wall
    
    /**
    *  Puts wall.
    *
    *  @param height Height of the wall.
    *  @param y      Y-ordinate position of the wall.
    */
    func putWallWithHeight(height: CGFloat, y:CGFloat)
    {
        let wall = SKSpriteNode(color: wallColor, size: CGSizeMake(kWallWidth, height))
        wall.position = CGPointMake(size.width + kWallWidth / 2.0, y)

        let body = SKPhysicsBody(rectangleOfSize: wall.size)
        body.affectedByGravity = false
        body.dynamic = false
        body.contactTestBitMask = 1
        wall.physicsBody = body

        wall.runAction(
            SKAction.sequence([
                SKAction.moveToX(-kWallWidth, duration: NSTimeInterval((size.width + kWallWidth) / kWallSpeed)),
                SKAction.removeFromParent()]))
        
        addChild(wall)
    }
    
    /**
    *  Puts 2 walls at the right edge of the screen.
    */
    func putWalls()
    {
        let upperWallHeight = kWallHeightUnit * CGFloat(arc4random() % (kUpperWallHeightMax - kUpperWallHeightMin) + kUpperWallHeightMin) + heightDiff
        let bottomWallHeight = size.height - upperWallHeight - kWallHeightUnit * CGFloat(kHoleHeight)
        
        putWallWithHeight(upperWallHeight, y: size.height - upperWallHeight / 2.0)
        putWallWithHeight(bottomWallHeight, y: bottomWallHeight / 2.0)
    }

    /**
    *  Puts walls periodically forever.
    */
    func putWallsPeriodically()
    {
        let pointAction = SKAction.sequence([
            SKAction.waitForDuration(timeForWallGoThroughBall),
            SKAction.runBlock({
                guard let 🐦 = self.childNodeWithName("🐦") else {
                    return
                }
                if 🐦.position.y > self.size.height {
                    self.gameOver()
                    self.runAction(SKAction.playSoundFileNamed("hit.caf", waitForCompletion: false))
                } else {
                    self.incrementPoints()
                }
            })
            ])
        
        runAction(
            SKAction.repeatActionForever(
                SKAction.sequence([
                    SKAction.waitForDuration(kIntervalBetweenWalls),
                    SKAction.runBlock({
                        guard self.phase == .Game else {
                            return
                        }
                        self.putWalls()
                        self.runAction(pointAction)
                    })])
            ))
    }
    
    // MARK: - 4. Points

    /**
    *  Puts the points label.
    */
    func putPointsLabel()
    {
        let label = SKLabelNode(fontNamed:fontName)
        label.name = "points"
        label.fontSize = 36.0
        label.fontColor = fontColor
        label.text = "0"
        label.position = CGPointMake(size.width / 2.0, size.height * 0.75)
        label.zPosition = 5000
        addChild(label)
    }
    
    /**
    *  Increments points and updates the points label.
    */
    func incrementPoints()
    {
        runAction(SKAction.playSoundFileNamed("score.caf", waitForCompletion: false))
        
        let label = childNodeWithName("points") as! SKLabelNode
        label.text = String(++points)
    }
    
    // MARK: - 5. Game Over
    
    /**
    *  Puts the game over label.
    */
    func putGameOverLabel() {
        let label = SKLabelNode(fontNamed:fontName)
        label.fontSize = 36.0
        label.fontColor = fontColor
        label.text = "Game Over"
        label.zPosition = 5000
        label.position = CGPointMake(size.width/2, size.height-36.0)

        let moveToAction = SKAction.moveToY(size.height/2.0, duration: 0.1)
        let blockAction = SKAction.runBlock({ self.phase = Phase.Medal })
        label.runAction(SKAction.sequence([moveToAction, blockAction]))
        
        addChild(label)
    }
    
}

// MARK: - SKPhysicsContactDelegate methods

extension GameScene : SKPhysicsContactDelegate {
    
    /**
     *  Moves to game over phase when the ball contacts with any other objects.
     *
     *  @param contact an object that describes the contact.
     */
    func didBeginContact(contact: SKPhysicsContact)
    {
        if phase == Phase.Game {
            gameOver()
        }
        runAction(SKAction.playSoundFileNamed("hit.caf", waitForCompletion: false))
    }
    
}
