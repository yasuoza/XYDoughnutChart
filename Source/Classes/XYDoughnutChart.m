#import "XYDoughnutChart.h"
#import <QuartzCore/QuartzCore.h>


@interface SliceLayer : CAShapeLayer

@property (nonatomic, assign) CGFloat   value;
@property (nonatomic, assign) CGFloat   percentage;
@property (nonatomic, assign) double    startAngle;
@property (nonatomic, assign) double    endAngle;
@property (nonatomic, assign) BOOL      selected;
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
    arcAnimation.fromValue = currentAngle;
    arcAnimation.toValue = to;
    arcAnimation.delegate = delegate;
    arcAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
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

@property(nonatomic, assign) CGPoint doughnutCenter;
@property(nonatomic, assign) CGFloat doughnutRadius;
@property(nonatomic, assign) CGFloat labelRadius;

- (void)updateTimerFired:(NSTimer *)timer;
- (SliceLayer *)createSliceLayer;
- (void)updateLabelForLayer:(SliceLayer *)sliceLayer;
- (void)delegateOfSelectionChangeFrom:(NSInteger)previousSelection to:(NSInteger)newSelection;

@end

@implementation XYDoughnutChart
{
    NSInteger _selectedSliceIndex;
    //pie view, contains all slices
    UIView  *_doughnutView;
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
    _doughnutView = [[UIView alloc] initWithFrame:self.frame];
    _doughnutView.backgroundColor = [UIColor clearColor];
    [self addSubview:_doughnutView];

    _selectedSliceIndex = -1;

    _animationDuration = 0.5f;
    _startDoughnutAngle = M_PI_2 * 3;

    self.doughnutRadius = MIN(self.frame.size.width/2, self.frame.size.height/2) - 10;
    self.doughnutCenter = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    self.labelFont = [UIFont boldSystemFontOfSize:MAX((int)self.doughnutRadius/10, 5)];
    _labelColor = [UIColor whiteColor];

    _showLabel = YES;
    _showPercentage = YES;
}

# pragma mark - Setter

- (void)setDoughnutCenter:(CGPoint)doughnutCenter
{
    _doughnutView.center = doughnutCenter;
}

- (void)setDoughnutRadius:(CGFloat)doughnutRadius
{
    _doughnutRadius = doughnutRadius;
    CGPoint origin = _doughnutView.frame.origin;
    CGRect frame = CGRectMake(origin.x + _doughnutCenter.x - doughnutRadius,
                              origin.y + _doughnutCenter.y - doughnutRadius,
                              doughnutRadius * 2,
                              doughnutRadius * 2);
    _doughnutCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    _doughnutView.frame = frame;
    _doughnutView.layer.cornerRadius = _doughnutRadius;
}

- (void)setBackgroundColor:(UIColor *)color
{
    _doughnutView.backgroundColor = color;
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

    self.doughnutRadius = MIN(self.bounds.size.width/2, self.bounds.size.height/2);
    self.doughnutCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.labelRadius = _doughnutRadius * 2 / 3;

    CALayer *parentLayer = [_doughnutView layer];
    NSArray *slicelayers = [parentLayer sublayers];

    _selectedSliceIndex = -1;
    [slicelayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *layer = (SliceLayer *)obj;
        if(layer.selected) {
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

    _doughnutView.userInteractionEnabled = NO;

    __block NSMutableArray *layersToRemove = nil;

    BOOL isOnStart = ([slicelayers count] == 0 && sliceCount);
    NSInteger diff = sliceCount - [slicelayers count];
    layersToRemove = [NSMutableArray arrayWithArray:slicelayers];

    BOOL onEnd = ([slicelayers count] && (sliceCount == 0 || sum <= 0));
    if (onEnd) {
        for(SliceLayer *layer in _doughnutView.layer.sublayers) {
            layer.value = 0.0;
            if (animated) {
                [layer createArcAnimationForKey:@"startAngle"
                                      fromValue:[NSNumber numberWithDouble:_startDoughnutAngle]
                                        toValue:[NSNumber numberWithDouble:_startDoughnutAngle]
                                       Delegate:self];
                [layer createArcAnimationForKey:@"endAngle"
                                      fromValue:[NSNumber numberWithDouble:_startDoughnutAngle]
                                        toValue:[NSNumber numberWithDouble:_startDoughnutAngle]
                                       Delegate:self];
            } else {
                layer.startAngle = _startDoughnutAngle;
                layer.endAngle = _startDoughnutAngle;
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
        double startFromAngle = _startDoughnutAngle + startToAngle;
        double endFromAngle = _startDoughnutAngle + endToAngle;

        if ( index >= [slicelayers count] ) {
            layer = [self createSliceLayer];
            if (isOnStart) {
                startFromAngle = endFromAngle = _startDoughnutAngle;
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
                startFromAngle = endFromAngle = _startDoughnutAngle;
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


        layer.fillColor = [self sliceColorAtIndex:index].CGColor;

        if ([_dataSource respondsToSelector:@selector(doughnutChart:textForSliceAtIndex:)]) {
            layer.text = [_dataSource doughnutChart:self textForSliceAtIndex:index];
        }

        layer.value = values[index];

        if (animated) {
            [layer createArcAnimationForKey:@"startAngle"
                                  fromValue:[NSNumber numberWithDouble:startFromAngle]
                                    toValue:[NSNumber numberWithDouble:startToAngle+_startDoughnutAngle]
                                   Delegate:self];
            [layer createArcAnimationForKey:@"endAngle"
                                  fromValue:[NSNumber numberWithDouble:endFromAngle]
                                    toValue:[NSNumber numberWithDouble:endToAngle+_startDoughnutAngle]
                                   Delegate:self];
        } else {
            [self updateLabelForLayer:layer];
            layer.startAngle = startToAngle + _startDoughnutAngle;
            layer.endAngle = endToAngle + _startDoughnutAngle;
        }

        startToAngle = endToAngle;
    }

    if (animated) {
        [CATransaction setDisableActions:YES];
    }

    for(SliceLayer *layer in layersToRemove) {
        layer.fillColor = [self backgroundColor].CGColor;
        layer.delegate = nil;
        layer.zPosition = 0;
        SliceTextLayer *textLayer = [[layer sublayers] objectAtIndex:0];
        textLayer.hidden = YES;
    }

    [layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SliceLayer *sliceLayer = obj;
        [[sliceLayer sublayers].firstObject removeFromSuperlayer];
        [sliceLayer removeFromSuperlayer];
    }];

    [layersToRemove removeAllObjects];

    for (SliceLayer *layer in _doughnutView.layer.sublayers) {
        layer.zPosition = kDefaultSliceZOrder;
    }

    _doughnutView.userInteractionEnabled = YES;

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
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        static float timeInterval = 1.0/60.0;
        NSTimer *aTimer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:aTimer forMode:NSRunLoopCommonModes];
    }];
}

# pragma mark - Touch Handing (Selection Notification)

- (NSInteger)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSUInteger selectedIndex = -1;

    CGAffineTransform transform = CGAffineTransformIdentity;

    CALayer *parentLayer = [_doughnutView layer];
    NSArray *sliceLayers = [parentLayer sublayers];

    [sliceLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
        CGPathRef path = [sliceLayer path];

        if (CGPathContainsPoint(path, &transform, point, 0)) {
            CGFloat strokeWidth = 1.0;
            if ([_delegate respondsToSelector:@selector(doughnutChart:selectedStrokeWidthForSliceAtIndex:)]) {
                strokeWidth = [_delegate doughnutChart:self selectedStrokeWidthForSliceAtIndex:idx];
            }
            sliceLayer.lineWidth = strokeWidth;
            UIColor *color = [UIColor colorWithCGColor:sliceLayer.fillColor];
            sliceLayer.fillColor = [color colorWithAlphaComponent:1.0].CGColor;

            CGColorRef strokeColor = [UIColor whiteColor].CGColor;
            if ([_delegate respondsToSelector:@selector(doughnutChart:selectedStrokeColorForSliceAtIndex:)]) {
                strokeColor = [_delegate doughnutChart:self selectedStrokeColorForSliceAtIndex:idx].CGColor;
            }
            sliceLayer.strokeColor = strokeColor;

            sliceLayer.lineJoin = kCALineJoinBevel;
            sliceLayer.zPosition = MAXFLOAT;
            selectedIndex = idx;
        } else {
            sliceLayer.zPosition = kDefaultSliceZOrder;
            UIColor *color = [self sliceColorAtIndex:idx];
            sliceLayer.fillColor = [color
                                  colorWithAlphaComponent:CGColorGetAlpha(color.CGColor)/4].CGColor;
            sliceLayer.lineWidth = 0.0;
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
    CGPoint point = [touch locationInView:_doughnutView];
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
    CGPoint point = [touch locationInView:_doughnutView];
    NSInteger selectedIndex = [self getCurrentSelectedOnTouch:point];
    [self delegateOfSelectionChangeFrom:_selectedSliceIndex to:selectedIndex];
    [self touchesCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    CALayer *parentLayer = [_doughnutView layer];
    NSArray *sliceLayers = [parentLayer sublayers];

    [CATransaction setDisableActions:YES];
    [sliceLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
        sliceLayer.fillColor = [self sliceColorAtIndex:idx].CGColor;
        sliceLayer.zPosition = kDefaultSliceZOrder;
        sliceLayer.lineWidth = 0.0;
    }];
    [CATransaction setDisableActions:NO];
}

# pragma mark - Selection Notification

- (void)delegateOfSelectionChangeFrom:(NSInteger)previousSelection to:(NSInteger)newSelection
{
    if (previousSelection != newSelection) {
        if (previousSelection != -1) {
            [self setSliceDeselectedAtIndex:previousSelection];
            [_delegate doughnutChart:self didDeselectSliceAtIndex:previousSelection];
            _selectedSliceIndex = -1;
        }
        if (newSelection != -1){
            [self setSliceSelectedAtIndex:newSelection];
            _selectedSliceIndex = newSelection;
            [_delegate doughnutChart:self didSelectSliceAtIndex:newSelection];
        }
    }
    else if (newSelection != -1){
        SliceLayer *layer = [_doughnutView.layer.sublayers objectAtIndex:newSelection];
        if (layer) {
            if (layer.selected) {
                [self setSliceDeselectedAtIndex:newSelection];

                [_delegate doughnutChart:self didDeselectSliceAtIndex:newSelection];
                _selectedSliceIndex = -1;
            }
        } else {
            [self setSliceSelectedAtIndex:newSelection];
            _selectedSliceIndex = newSelection;
            [_delegate doughnutChart:self didSelectSliceAtIndex:newSelection];
        }
    }
}

# pragma mark - Selection Programmatically Without Notification

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = [_doughnutView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.selected) {
        layer.selected = YES;
    }
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = [_doughnutView.layer.sublayers objectAtIndex:index];
    if (layer && layer.selected) {
        layer.selected = NO;
    }
}

# pragma mark - Pie Layer Creation Method

- (SliceLayer *)createSliceLayer
{
    SliceLayer *sliceLayer = [SliceLayer layer];
    sliceLayer.zPosition = 0;
    sliceLayer.strokeColor = nil;
    SliceTextLayer *textLayer = [SliceTextLayer layer];
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    CGFontRef font = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        font = CGFontCreateCopyWithVariations((__bridge CGFontRef)(self.labelFont), (__bridge CFDictionaryRef)(@{}));
    } else {
        font = CGFontCreateWithFontName((__bridge CFStringRef)[self.labelFont fontName]);
    }
    if (font) {
        textLayer.font = font;
        CFRelease(font);
    }
    textLayer.fontSize = self.labelFont.pointSize;
    textLayer.anchorPoint = CGPointMake(0.5, 0.5);
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.backgroundColor = [UIColor clearColor].CGColor;
    textLayer.foregroundColor = self.labelColor.CGColor;
    if (self.labelShadowColor) {
        textLayer.shadowColor = self.labelShadowColor.CGColor;
        textLayer.shadowOffset = CGSizeZero;
        textLayer.shadowOpacity = 1.0f;
        textLayer.shadowRadius = 2.0f;
    }
    CGSize size = [@"0" sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];
    [CATransaction setDisableActions:YES];
    textLayer.frame = CGRectMake(0, 0, size.width, size.height);
    textLayer.position = CGPointMake(_doughnutCenter.x + (_labelRadius * cos(0)), _doughnutCenter.y + (_labelRadius * sin(0)));
    [CATransaction setDisableActions:NO];
    [sliceLayer addSublayer:textLayer];
    return sliceLayer;
}

- (void)updateLayerAngle:(BOOL)animated
{
    CALayer *parentLayer = [_doughnutView layer];
    NSArray *sliceLayers = [parentLayer sublayers];

    [CATransaction setDisableActions:YES];
    [sliceLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
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

        CGPathRef path = CGPathCreateArc(_doughnutCenter, _doughnutRadius, interpolatedStartAngle, interpolatedEndAngle);
        sliceLayer.path = path;
        sliceLayer.lineWidth = 0.0;
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

                labelLayer.position = CGPointMake(_doughnutCenter.x + (_labelRadius * cos(interpolatedMidAngle)),
                                                  _doughnutCenter.y + (_labelRadius * sin(interpolatedMidAngle)));

                NSString *valueText = [labelLayer valueAtSliceLayer:sliceLayer byPercentage:_showPercentage];

                CGSize size = [valueText sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];
                labelLayer.bounds = CGRectMake(0, 0, size.width, size.height);
                CGFloat labelLayerWidth = abs(_labelRadius * cos(interpolatedStartAngle)
                                              - _labelRadius * cos(interpolatedEndAngle));
                CGFloat labelLayerHeight = abs(_labelRadius * sin(interpolatedStartAngle)
                                          - _labelRadius * sin(interpolatedEndAngle));
                if (MAX(labelLayerWidth, labelLayerHeight) < MAX(size.width,size.height) || sliceLayer.value <= 0) {
                    labelLayer.string = @"";
                } else {
                    labelLayer.string = valueText;
                }
            }
        }
    }];
    [CATransaction setDisableActions:NO];
}

- (void)updateLabelForLayer:(SliceLayer *)sliceLayer
{
    SliceTextLayer *labelLayer = [[sliceLayer sublayers] objectAtIndex:0];

    labelLayer.hidden = !_showLabel;

    if(!_showLabel) return;

    NSString *valueText = [labelLayer valueAtSliceLayer:sliceLayer byPercentage:_showPercentage];

    CGSize size = [valueText sizeWithAttributes:@{NSFontAttributeName: self.labelFont}];

    [CATransaction setDisableActions:YES];

    labelLayer.bounds = CGRectMake(0, 0, size.width, size.height);

    if (M_PI*2*_labelRadius*sliceLayer.percentage < MAX(size.width,size.height) || sliceLayer.value <= 0) {
        labelLayer.string = @"";
    } else {
        labelLayer.string = valueText;
    }

    [CATransaction setDisableActions:NO];
}

- (UIColor *)sliceColorAtIndex:(NSUInteger)index
{
    if ([_delegate respondsToSelector:@selector(doughnutChart:colorForSliceAtIndex:)]) {
        return [_delegate doughnutChart:self colorForSliceAtIndex:index];
    }
    return [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
}

@end
