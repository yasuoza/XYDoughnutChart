#import "XYDoughnutChart.h"
#import <QuartzCore/QuartzCore.h>


@interface SliceLayer : CAShapeLayer
@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      isSelected;
@property (nonatomic, strong) NSString  *text;

- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate;
@end

@implementation SliceLayer

- (id)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer]) {
        if ([layer isKindOfClass:[SliceLayer class]]) {
            self.startAngle = [(SliceLayer *)layer startAngle];
            self.endAngle = [(SliceLayer *)layer endAngle];
        }
    }
    return self;
}

- (void)createArcAnimationForKey:(NSString *)key fromValue:(NSNumber *)from toValue:(NSNumber *)to Delegate:(id)delegate
{
    CABasicAnimation *arcAnimation = [CABasicAnimation animationWithKeyPath:key];
    NSNumber *currentAngle = [[self presentationLayer] valueForKey:key];
    if(!currentAngle) currentAngle = from;
    [arcAnimation setFromValue:currentAngle];
    [arcAnimation setToValue:to];
    [arcAnimation setDelegate:delegate];
    [arcAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
    [self addAnimation:arcAnimation forKey:key];
    [self setValue:to forKey:key];
}
@end


@interface SliceTextLayer : CATextLayer
- (NSString *)valueAtSliceLayer:(SliceLayer *)sliceLayer byPercentage:(BOOL)byPercentage;
@end

@implementation SliceTextLayer

- (NSString *)valueAtSliceLayer:(SliceLayer *)sliceLayer byPercentage:(BOOL)byPercentage
{
    CGFloat value = sliceLayer.value;
    NSString *label;
    if (byPercentage) {
        label = [NSString stringWithFormat:@"%0.0f", sliceLayer.percentage*100];
    } else {
        label = (sliceLayer.text) ? sliceLayer.text : [NSString stringWithFormat:@"%0.0f", value];
    }
    return label;
}

@end


@interface XYDoughnutChart ()
@property(nonatomic, assign) CGPoint pieCenter;
@property(nonatomic, assign) CGFloat pieRadius;

- (void)updateTimerFired:(NSTimer *)timer;
- (SliceLayer *)createSliceLayer;
- (void)updateLabelForLayer:(SliceLayer *)pieLayer value:(CGFloat)value;
- (void)delegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection;
@end

@implementation XYDoughnutChart
{
    NSInteger _selectedSliceIndex;
    //pie view, contains all slices
    UIView  *_pieView;

    //animation control
    NSTimer *_animationTimer;
    NSMutableArray *_animations;
}

static NSUInteger kDefaultSliceZOrder = 100;

static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL, center.x + radius / 3 * cos(startAngle), center.y + radius / 3 * sin(startAngle));
    CGPathAddLineToPoint(path, NULL, center.x + radius * cos(startAngle), center.y + radius * sin(startAngle));
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, false);
    CGPathAddLineToPoint(path, NULL, center.x + radius / 3 * cos(endAngle), center.y + radius / 3 * sin(endAngle));
    CGPathAddArc(path, NULL, center.x, center.y, radius / 3, endAngle, startAngle, true);

    CGPathCloseSubpath(path);

    return path;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self constructChartView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self constructChartView];
    }
    return self;
}

- (void)constructChartView
{
    _pieView = [[UIView alloc] initWithFrame:self.frame];
    [_pieView setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_pieView];

    _selectedSliceIndex = -1;
    _animations = [[NSMutableArray alloc] init];

    _animationDuration = 0.5f;
    _startPieAngle = M_PI_2*3;
    _selectedSliceStroke = 3.0;

    self.pieRadius = MIN(self.frame.size.width/2, self.frame.size.height/2) - 10;
    self.pieCenter = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.pieRadius/10, 5)];
    _labelColor = [UIColor whiteColor];

    _showLabel = YES;
    _showPercentage = YES;
}

# pragma mark - Setter

- (void)setPieCenter:(CGPoint)pieCenter
{
    [_pieView setCenter:pieCenter];
}

- (void)setPieRadius:(CGFloat)pieRadius
{
    _pieRadius = pieRadius;
    CGPoint origin = _pieView.frame.origin;
    CGRect frame = CGRectMake(origin.x + _pieCenter.x - pieRadius,
                              origin.y + _pieCenter.y - pieRadius,
                              pieRadius * 2,
                              pieRadius * 2);
    _pieCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    [_pieView setFrame:frame];
    [_pieView.layer setCornerRadius:_pieRadius];
}

- (void)setPieBackgroundColor:(UIColor *)color
{
    [_pieView setBackgroundColor:color];
}

# pragma mark - manage settings

- (void)setShowPercentage:(BOOL)showPercentage
{
    _showPercentage = showPercentage;
    for(SliceLayer *layer in _pieView.layer.sublayers) {
        CATextLayer *textLayer = [[layer sublayers] objectAtIndex:0];
        [textLayer setHidden:!_showLabel];
        if(!_showLabel) return;
        NSString *label;
        if (_showPercentage) {
            label = [NSString stringWithFormat:@"%0.0f", layer.percentage*100];
        } else {
            label = (layer.text)?layer.text:[NSString stringWithFormat:@"%0.0f", layer.value];
        }

        CGSize size = [label sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];

        if(M_PI*2*_labelRadius*layer.percentage < MAX(size.width,size.height)) {
            [textLayer setString:@""];
        } else {
            [textLayer setString:label];
            [textLayer setBounds:CGRectMake(0, 0, size.width, size.height)];
        }
    }
}

# pragma mark - Pie Reload Data With Animation

- (void)reloadData
{
    [self reloadData:NO];
}

- (void)reloadData:(BOOL)animated
{
    if (_dataSource == nil) {
        return;
    }

    self.pieRadius = MIN(self.bounds.size.width/2, self.bounds.size.height/2);
    self.pieCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.labelRadius = _pieRadius * 2 / 3;

    CALayer *parentLayer = [_pieView layer];
    NSArray *slicelayers = [parentLayer sublayers];

    _selectedSliceIndex = -1;
    [slicelayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *layer = (SliceLayer *)obj;
        if(layer.isSelected) {
            [self setSliceDeselectedAtIndex:idx];
        }
    }];

    double startToAngle = 0.0;
    double endToAngle = startToAngle;

    NSUInteger sliceCount = [_dataSource numberOfSlicesInDoughnutChart:self];

    double sum = 0.0;
    double values[sliceCount];
    for (int index = 0; index < sliceCount; index++) {
        values[index] = [_dataSource doughnutChart:self valueForSliceAtIndex:index];
        sum += values[index];
    }

    double angles[sliceCount], div;
    for (int index = 0; index < sliceCount; index++) {
        div = sum == 0? 0 : values[index] / sum;
        angles[index] = M_PI * 2 * div;
    }

    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:_animationDuration];
    }

    [_pieView setUserInteractionEnabled:NO];

    __block NSMutableArray *layersToRemove = nil;

    BOOL isOnStart = ([slicelayers count] == 0 && sliceCount);
    NSInteger diff = sliceCount - [slicelayers count];
    layersToRemove = [NSMutableArray arrayWithArray:slicelayers];

    BOOL onEnd = ([slicelayers count] && (sliceCount == 0 || sum <= 0));
    if (onEnd) {
        for(SliceLayer *layer in _pieView.layer.sublayers) {
            [self updateLabelForLayer:layer value:0];
            if (animated) {
                [layer createArcAnimationForKey:@"startAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
                [layer createArcAnimationForKey:@"endAngle"
                                      fromValue:[NSNumber numberWithDouble:_startPieAngle]
                                        toValue:[NSNumber numberWithDouble:_startPieAngle]
                                       Delegate:self];
            } else {
                layer.startAngle = _startPieAngle;
                layer.endAngle = _startPieAngle;
            }
        }

        if (animated) {
            [CATransaction commit];
        } else {
            [self updateLayerAngle:NO];
        }

        return;
    }

    for(int index = 0; index < sliceCount; index ++) {
        SliceLayer *layer;
        double angle = angles[index];
        endToAngle += angle;
        double startFromAngle = _startPieAngle + startToAngle;
        double endFromAngle = _startPieAngle + endToAngle;

        if ( index >= [slicelayers count] ) {
            layer = [self createSliceLayer];
            if (isOnStart) {
                startFromAngle = endFromAngle = _startPieAngle;
            }
            [parentLayer addSublayer:layer];
            diff--;
        } else {
            SliceLayer *onelayer = [slicelayers objectAtIndex:index];
            if(diff == 0 || onelayer.value == (CGFloat)values[index]) {
                layer = onelayer;
                [layersToRemove removeObject:layer];
            }
            else if(diff > 0) {
                layer = [self createSliceLayer];
                startFromAngle = endFromAngle = _startPieAngle;
                [parentLayer insertSublayer:layer atIndex:index];
                diff--;
            }
            else if(diff < 0) {
                while(diff < 0) {
                    [onelayer removeFromSuperlayer];
                    [parentLayer addSublayer:onelayer];
                    diff++;
                    onelayer = [slicelayers objectAtIndex:index];
                    if (onelayer.value == (CGFloat)values[index] || diff == 0) {
                        layer = onelayer;
                        [layersToRemove removeObject:layer];
                        break;
                    }
                }
            }
        }

        layer.value = values[index];
        layer.percentage = (sum)?layer.value/sum:0;
        UIColor *color = nil;
        if([_dataSource respondsToSelector:@selector(doughnutChart:colorForSliceAtIndex:)]) {
            color = [_dataSource doughnutChart:self colorForSliceAtIndex:index];
        }

        if(!color) {
            color = [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
        }

        [layer setFillColor:color.CGColor];
        if([_dataSource respondsToSelector:@selector(doughnutChart:textForSliceAtIndex:)]) {
            layer.text = [_dataSource doughnutChart:self textForSliceAtIndex:index];
        }

        layer.value = values[index];

        if (animated) {
            [layer createArcAnimationForKey:@"startAngle"
                                  fromValue:[NSNumber numberWithDouble:startFromAngle]
                                    toValue:[NSNumber numberWithDouble:startToAngle+_startPieAngle]
                                   Delegate:self];
            [layer createArcAnimationForKey:@"endAngle"
                                  fromValue:[NSNumber numberWithDouble:endFromAngle]
                                    toValue:[NSNumber numberWithDouble:endToAngle+_startPieAngle]
                                   Delegate:self];
        } else {
            [self updateLabelForLayer:layer value:layer.value];
            layer.startAngle = startToAngle + _startPieAngle;
            layer.endAngle = endToAngle + _startPieAngle;
        }

        startToAngle = endToAngle;
    }

    if (animated) {
        [CATransaction setDisableActions:YES];
    }

    for(SliceLayer *layer in layersToRemove) {
        [layer setFillColor:[self backgroundColor].CGColor];
        [layer setDelegate:nil];
        [layer setZPosition:0];
        SliceTextLayer *textLayer = [[layer sublayers] objectAtIndex:0];
        [textLayer setHidden:YES];
    }

    [layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperlayer];
    }];

    [layersToRemove removeAllObjects];

    for (SliceLayer *layer in _pieView.layer.sublayers) {
        [layer setZPosition:kDefaultSliceZOrder];
    }

    [_pieView setUserInteractionEnabled:YES];

    if (animated) {
        [CATransaction setDisableActions:NO];
        [CATransaction commit];
    } else {
        [self updateLayerAngle:animated];
    }
}

# pragma mark - Animation Delegate + Run Loop Timer

- (void)updateTimerFired:(NSTimer *)timer;
{
    [self updateLayerAngle:YES];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    if (_animationTimer == nil) {
        static float timeInterval = 1.0/60.0;
        // Run the animation timer on the main thread.
        // We want to allow the user to interact with the UI while this timer is running.
        // If we run it on this thread, the timer will be halted while the user is touching the screen (that's why the chart was disappearing in our collection view).
        _animationTimer= [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_animationTimer forMode:NSRunLoopCommonModes];
    }

    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted
{
    [_animations removeObject:anim];

    if ([_animations count] == 0) {
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

# pragma mark - Touch Handing (Selection Notification)

- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSUInteger selectedIndex = -1;

    CGAffineTransform transform = CGAffineTransformIdentity;

    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];

    [pieLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *pieLayer = (SliceLayer *)obj;
        CGPathRef path = [pieLayer path];

        if (CGPathContainsPoint(path, &transform, point, 0)) {
            [pieLayer setLineWidth:_selectedSliceStroke];
            UIColor *color = [UIColor colorWithCGColor:pieLayer.fillColor];
            [pieLayer setFillColor:[color colorWithAlphaComponent:1.0].CGColor];
            [pieLayer setStrokeColor:[UIColor whiteColor].CGColor];
            [pieLayer setLineJoin:kCALineJoinBevel];
            [pieLayer setZPosition:MAXFLOAT];
            selectedIndex = idx;
        } else {
            [pieLayer setZPosition:kDefaultSliceZOrder];
            UIColor *color = [UIColor colorWithCGColor:pieLayer.fillColor];
            [pieLayer setFillColor:[color colorWithAlphaComponent:0.25].CGColor];
            [pieLayer setLineWidth:0.0];
        }
    }];
    return selectedIndex;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    NSInteger newlySelectedIndex = [self getCurrentSelectedOnTouch:point];

    if (newlySelectedIndex != _selectedSliceIndex) {
        [self delegateOfSelectionChangeFrom:_selectedSliceIndex to:newlySelectedIndex];
    }

    if (newlySelectedIndex == -1) {
        [self touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_pieView];
    NSInteger selectedIndex = [self getCurrentSelectedOnTouch:point];
    [self delegateOfSelectionChangeFrom:_selectedSliceIndex to:selectedIndex];
    [self touchesCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];

    for (SliceLayer *pieLayer in pieLayers) {
        UIColor *color = [UIColor colorWithCGColor:pieLayer.fillColor];
        [pieLayer setFillColor:[color colorWithAlphaComponent:1.0].CGColor];
        [pieLayer setZPosition:kDefaultSliceZOrder];
        [pieLayer setLineWidth:0.0];
    }
}

# pragma mark - Selection Notification

- (void)delegateOfSelectionChangeFrom:(NSUInteger)previousSelection to:(NSUInteger)newSelection
{
    if (previousSelection == newSelection) {
        return;
    }

    if (previousSelection != -1) {
        NSUInteger tempPre = previousSelection;
        [self setSliceDeselectedAtIndex:tempPre];
        previousSelection = newSelection;
        if([_delegate respondsToSelector:@selector(doughnutChart:didDeselectSliceAtIndex:)]) {
            [_delegate doughnutChart:self didDeselectSliceAtIndex:tempPre];
        }
    }

    if (newSelection == -1) {
        _selectedSliceIndex = newSelection;
        return;
    }

    [self setSliceSelectedAtIndex:newSelection];

    _selectedSliceIndex = newSelection;
    if ([_delegate respondsToSelector:@selector(doughnutChart:didSelectSliceAtIndex:)]) {
        [_delegate doughnutChart:self didSelectSliceAtIndex:newSelection];
    }
}

# pragma mark - Selection Programmatically Without Notification

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.isSelected) {
        layer.isSelected = YES;
    }
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = [_pieView.layer.sublayers objectAtIndex:index];
    if (layer && layer.isSelected) {
        layer.position = CGPointMake(0, 0);
        layer.isSelected = NO;
    }
}

# pragma mark - Pie Layer Creation Method

- (SliceLayer *)createSliceLayer
{
    SliceLayer *pieLayer = [SliceLayer layer];
    [pieLayer setZPosition:0];
    [pieLayer setStrokeColor:NULL];
    SliceTextLayer *textLayer = [SliceTextLayer layer];
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        [textLayer setFont:font];
        CFRelease(font);
    }
    [textLayer setFontSize:self.labelFont.pointSize];
    [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    [textLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [textLayer setForegroundColor:self.labelColor.CGColor];
    if (self.labelShadowColor) {
        [textLayer setShadowColor:self.labelShadowColor.CGColor];
        [textLayer setShadowOffset:CGSizeZero];
        [textLayer setShadowOpacity:1.0f];
        [textLayer setShadowRadius:2.0f];
    }
    CGSize size = [@"0" sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];
    [CATransaction setDisableActions:YES];
    [textLayer setFrame:CGRectMake(0, 0, size.width, size.height)];
    [textLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(0)), _pieCenter.y + (_labelRadius * sin(0)))];
    [CATransaction setDisableActions:NO];
    [pieLayer addSublayer:textLayer];
    return pieLayer;
}

- (void)updateLayerAngle:(BOOL)animated
{
    CALayer *parentLayer = [_pieView layer];
    NSArray *pieLayers = [parentLayer sublayers];

    [pieLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
        NSNumber *presentationLayerStartAngle = [sliceLayer valueForKey:@"startAngle"];
        if (animated) {
            presentationLayerStartAngle = [[sliceLayer presentationLayer] valueForKey:@"startAngle"];
        }
        CGFloat interpolatedStartAngle = [presentationLayerStartAngle doubleValue];

        NSNumber *presentationLayerEndAngle = [sliceLayer valueForKey:@"endAngle"];
        if (animated) {
            presentationLayerEndAngle = [[sliceLayer presentationLayer] valueForKey:@"endAngle"];
        }
        CGFloat interpolatedEndAngle = [presentationLayerEndAngle doubleValue];

        CGPathRef path = CGPathCreateArc(_pieCenter, _pieRadius, interpolatedStartAngle, interpolatedEndAngle);
        [sliceLayer setPath:path];
        CFRelease(path);

        {
            SliceTextLayer *labelLayer = [[sliceLayer sublayers] objectAtIndex:0];
            CGFloat interpolatedMidAngle = (interpolatedEndAngle + interpolatedStartAngle) / 2;

            if (interpolatedEndAngle == interpolatedStartAngle) {
                labelLayer.hidden = YES;
                return;
            }

            if (_showLabel) {
                labelLayer.hidden = NO;
                [CATransaction setDisableActions:YES];
                [labelLayer setPosition:CGPointMake(_pieCenter.x + (_labelRadius * cos(interpolatedMidAngle)),
                                                    _pieCenter.y + (_labelRadius * sin(interpolatedMidAngle)))];


                NSString *valueText = [labelLayer valueAtSliceLayer:sliceLayer byPercentage:_showPercentage];

                CGSize size = [valueText sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];
                [labelLayer setBounds:CGRectMake(0, 0, size.width, size.height)];
                CGFloat labelLayerWidth = abs(_labelRadius * cos(interpolatedStartAngle)
                                         - _labelRadius * cos(interpolatedEndAngle));
                CGFloat labelLayerHeight = abs(_labelRadius * sin(interpolatedStartAngle)
                                          - _labelRadius * sin(interpolatedEndAngle));
                if (MAX(labelLayerWidth, labelLayerHeight) < MAX(size.width,size.height)
                    || sliceLayer.value <= 0) {
                    labelLayer.string = @"";
                } else {
                    labelLayer.string = valueText;
                }
            }

            [CATransaction setDisableActions:NO];
        }
    }];
}

- (void)updateLabelForLayer:(SliceLayer *)sliceLayer value:(CGFloat)value
{
    SliceTextLayer *labelLayer = [[sliceLayer sublayers] objectAtIndex:0];

    [labelLayer setHidden:!_showLabel];

    if(!_showLabel) return;

    NSString *valueText = [labelLayer valueAtSliceLayer:sliceLayer byPercentage:_showPercentage];

    CGSize size = [valueText sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];

    [CATransaction setDisableActions:YES];

    [labelLayer setBounds:CGRectMake(0, 0, size.width, size.height)];

    if (M_PI*2*_labelRadius*sliceLayer.percentage < MAX(size.width,size.height) || value <= 0) {
        labelLayer.string = @"";
    } else {
        labelLayer.string = valueText;
    }

    [CATransaction setDisableActions:NO];
}

@end
