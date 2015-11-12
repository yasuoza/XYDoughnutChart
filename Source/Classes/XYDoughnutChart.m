@import QuartzCore;
#import "XYDoughnutChart.h"
#import "NSIndexPath+XYDoughnutChart.h"

# pragma mark - SliceLayer

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

# pragma mark - SliceTextLayer

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

# pragma mark - XYDoughnutChart

@interface XYDoughnutChart ()

@property (nonatomic, assign) CGPoint doughnutCenter;
@property (nonatomic, assign) CGFloat doughnutRadius;
@property (nonatomic, assign) CGFloat labelRadius;
@property (nonatomic, strong) CADisplayLink *displayLink;

- (SliceLayer *)createSliceLayer;
- (void)updateLabelForLayer:(SliceLayer *)sliceLayer;
- (void)delegateOfSelectionChangeFrom:(NSIndexPath *)previousIndexPath to:(NSIndexPath *)newIndexPath;

@end

@implementation XYDoughnutChart
{
    NSIndexPath *_selectedIndexPath;

    UIView  *_doughnutView;
}

static NSUInteger kDefaultSliceZOrder = 100;

static CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat radiusOffset,
                                 CGFloat startAngle, CGFloat endAngle)
{
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathMoveToPoint(path, NULL,
                      center.x + radius * radiusOffset * cos(startAngle),
                      center.y + radius * radiusOffset * sin(startAngle));
    CGPathAddLineToPoint(path, NULL,
                         center.x + radius * cos(startAngle),
                         center.y + radius * sin(startAngle));
    CGPathAddArc(path, NULL,
                 center.x, center.y, radius,
                 startAngle, endAngle, false);
    CGPathAddLineToPoint(path, NULL,
                         center.x + radius * radiusOffset * cos(endAngle),
                         center.y + radius * radiusOffset * sin(endAngle));
    CGPathAddArc(path, NULL, center.x, center.y, radius * radiusOffset, endAngle, startAngle, true);

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

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.doughnutRadius = MIN(self.bounds.size.width/2, self.bounds.size.height/2);
    self.doughnutCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.labelRadius = (_doughnutRadius + _doughnutRadius * _radiusOffset) / 2;
}

- (void)constructChartView
{
    _doughnutView = [[UIView alloc] initWithFrame:self.frame];
    _doughnutView.backgroundColor = [UIColor clearColor];
    [self addSubview:_doughnutView];

    _selectedIndexPath = nil;

    _animationDuration = 0.5f;
    _startDoughnutAngle = M_PI_2 * 3;
    _radiusOffset = 1.0 / 3.0;

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

-(void)setBackgroundColor:(UIColor * __nullable)color
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
    self.labelRadius = (_doughnutRadius + _doughnutRadius * _radiusOffset) / 2;

    CALayer *parentLayer = [_doughnutView layer];
    NSArray *slicelayers = [parentLayer sublayers];

    _selectedIndexPath = nil;
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
        values[index] = [_dataSource doughnutChart:self valueForSliceAtIndexPath:[NSIndexPath indexPathForSlice:index]];
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

    BOOL onStart = ([slicelayers count] == 0 && sliceCount > 0);
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
            [_displayLink invalidate];
            _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimatingLayerAngle:)];
            [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForSlice:index];

        if ( index >= [slicelayers count] ) {
            layer = [self createSliceLayer];
            if (onStart) {
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
        layer.percentage = sum ? layer.value / sum : 0;
        layer.fillColor = [self sliceColorAtIndex:index].CGColor;

        if ([_dataSource respondsToSelector:@selector(doughnutChart:textForSliceAtIndexPath:)]) {
            layer.text = [_dataSource doughnutChart:self textForSliceAtIndexPath:indexPath];
        }

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
        SliceTextLayer *textLayer = (SliceTextLayer *)[[layer sublayers] objectAtIndex:0];
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
        [_displayLink invalidate];
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimatingLayerAngle:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

        [CATransaction setDisableActions:NO];
        [CATransaction commit];
    } else {
        [self updateLayerAngle:animated];
    }
}

# pragma mark - Animation Delegate + Run Loop Timer

-(void)updateAnimatingLayerAngle:(CADisplayLink *)link {
    [self updateLayerAngle:YES];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        [_displayLink invalidate];
    }
}

# pragma mark - Touch Handing (Selection Notification)

- (NSIndexPath *)getCurrentSelectedOnTouch:(CGPoint)point
{
    __block NSIndexPath *indexPath = nil;

    CGAffineTransform transform = CGAffineTransformIdentity;

    CALayer *parentLayer = [_doughnutView layer];
    NSArray *sliceLayers = [parentLayer sublayers];

    [sliceLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
        CGPathRef path = [sliceLayer path];
        if (CGPathContainsPoint(path, &transform, point, 0)) {
            indexPath = [NSIndexPath indexPathForSlice:idx];
        }
    }];
    return indexPath;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:_doughnutView];
    NSIndexPath *newIndexPath = [self getCurrentSelectedOnTouch:point];

    if (!newIndexPath) {
        return [self touchesEnded:touches withEvent:event];
    }

    if (newIndexPath) {
        [self delegateOfSelectionChangeFrom:_selectedIndexPath to:newIndexPath];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self delegateOfSelectionChangeFrom:_selectedIndexPath to:nil];
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

- (void)delegateOfSelectionChangeFrom:(NSIndexPath *)previousIndexPath to:(NSIndexPath *)newIndexPath
{
    if (previousIndexPath == nil && newIndexPath == nil) {
        return;
    }

    if (previousIndexPath == nil) {
        _selectedIndexPath = [NSIndexPath indexPathForSlice:newIndexPath.slice];
        if ([_delegate respondsToSelector:@selector(doughnutChart:willSelectSliceAtIndex:)]) {
            if (![_delegate doughnutChart:self willSelectSliceAtIndex:[NSIndexPath indexPathForSlice:newIndexPath.slice]]) {
                return;
            }
        }
        [self setSliceSelectedAtIndex:newIndexPath.slice];
        [self updateSliceLayersSelected:newIndexPath.slice];
        if ([_delegate respondsToSelector:@selector(doughnutChart:didSelectSliceAtIndexPath:)]) {
            [_delegate doughnutChart:self didSelectSliceAtIndexPath:newIndexPath];
        }
        return;
    }

    if (newIndexPath == nil) {
        [self setSliceDeselectedAtIndex:previousIndexPath.slice];

        // Set to nil before calling the delegate to it can check if any other
        // slices are selected or if the user had fully deselected all slices.
        _selectedIndexPath = nil;

        if ([_delegate respondsToSelector:@selector(doughnutChart:didDeselectSliceAtIndexPath:)]) {
            [_delegate doughnutChart:self didDeselectSliceAtIndexPath:previousIndexPath];
        }

        return;
    }

    if (previousIndexPath.slice != newIndexPath.slice) {
        [self setSliceDeselectedAtIndex:previousIndexPath.slice];
        if ([_delegate respondsToSelector:@selector(doughnutChart:didDeselectSliceAtIndexPath:)]) {
            [_delegate doughnutChart:self didDeselectSliceAtIndexPath:previousIndexPath];
        }
        _selectedIndexPath = [NSIndexPath indexPathForSlice:newIndexPath.slice];
        if ([_delegate respondsToSelector:@selector(doughnutChart:willSelectSliceAtIndex:)]) {
            if (![_delegate doughnutChart:self willSelectSliceAtIndex:[NSIndexPath indexPathForSlice:newIndexPath.slice]]) {
                return;
            }
        }
        [self setSliceSelectedAtIndex:newIndexPath.slice];
        [self updateSliceLayersSelected:newIndexPath.slice];
        if ([_delegate respondsToSelector:@selector(doughnutChart:didSelectSliceAtIndexPath:)]) {
            [_delegate doughnutChart:self didSelectSliceAtIndexPath:newIndexPath];
        }
    }
}

# pragma mark - Selection Programmatically Without Notification

- (void)setSliceSelectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = (SliceLayer *)[_doughnutView.layer.sublayers objectAtIndex:index];
    if (layer && !layer.selected) {
        layer.selected = YES;
    }
}

- (void)setSliceDeselectedAtIndex:(NSInteger)index
{
    SliceLayer *layer = (SliceLayer *)[_doughnutView.layer.sublayers objectAtIndex:index];
    if (layer && layer.selected) {
        layer.selected = NO;
    }
}

# pragma mark - Selection Programmatically With Notification

- (void)selectSliceAtIndex:(NSInteger)index
{
  if (_dataSource == nil) {
    return;
  }

  NSInteger sliceCount = [_dataSource numberOfSlicesInDoughnutChart:self];

  if (index < sliceCount) {
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForSlice:index];
    [self delegateOfSelectionChangeFrom:_selectedIndexPath to:newIndexPath];
  }
}

- (void)deselectAllSlices
{
  [self delegateOfSelectionChangeFrom:_selectedIndexPath to:nil];
  [self touchesCancelled:nil withEvent:nil];
}

- (BOOL)isCurrentlyBeingSelected
{
  return _selectedIndexPath != nil;
}

# pragma mark - Slice Layer Creation Method

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

# pragma mark - Slice Layer Update Method

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

        CGPathRef path = CGPathCreateArc(_doughnutCenter, _doughnutRadius, _radiusOffset,
                                         interpolatedStartAngle, interpolatedEndAngle);
        sliceLayer.path = path;
        sliceLayer.lineWidth = 0.0;
        CFRelease(path);

        {
            SliceTextLayer *labelLayer = (SliceTextLayer *)[[sliceLayer sublayers] objectAtIndex:0];
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
                CGFloat labelLayerWidth = fabs(_labelRadius * cos(interpolatedStartAngle)
                                              - _labelRadius * cos(interpolatedEndAngle));
                CGFloat labelLayerHeight = fabs(_labelRadius * sin(interpolatedStartAngle)
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

- (void)updateSliceLayersSelected:(NSUInteger)selectedIndex
{
    CALayer *parentLayer = [_doughnutView layer];
    NSArray *sliceLayers = [parentLayer sublayers];

    [sliceLayers enumerateObjectsUsingBlock:^(SliceLayer *sliceLayer, NSUInteger idx, BOOL *stop) {
        if (idx == selectedIndex) {
            CGFloat strokeWidth = 1.0;
            if ([_delegate respondsToSelector:@selector(doughnutChart:selectedStrokeWidthForSliceAtIndexPath:)]) {
                strokeWidth = [_delegate doughnutChart:self selectedStrokeWidthForSliceAtIndexPath:[NSIndexPath indexPathForSlice:idx]];
            }
            sliceLayer.lineWidth = strokeWidth;
            UIColor *color = [UIColor colorWithCGColor:sliceLayer.fillColor];
            sliceLayer.fillColor = [color colorWithAlphaComponent:1.0].CGColor;

            CGColorRef strokeColor = [UIColor whiteColor].CGColor;
            if ([_delegate respondsToSelector:@selector(doughnutChart:selectedStrokeColorForSliceAtIndexPath:)]) {
                strokeColor = [_delegate doughnutChart:self selectedStrokeColorForSliceAtIndexPath:[NSIndexPath indexPathForSlice:idx]].CGColor;
            }
            sliceLayer.strokeColor = strokeColor;

            sliceLayer.lineJoin = kCALineJoinBevel;
            sliceLayer.zPosition = MAXFLOAT;
        } else {
            sliceLayer.zPosition = kDefaultSliceZOrder;
            UIColor *color = [self sliceColorAtIndex:idx];
            sliceLayer.fillColor = [color
                                    colorWithAlphaComponent:CGColorGetAlpha(color.CGColor)/4].CGColor;
            sliceLayer.lineWidth = 0.0;
        }
    }];
}

- (void)updateLabelForLayer:(SliceLayer *)sliceLayer
{
    SliceTextLayer *labelLayer = (SliceTextLayer *)[[sliceLayer sublayers] objectAtIndex:0];

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

- (UIColor *)sliceColorAtIndex:(NSInteger)index
{
    if ([_delegate respondsToSelector:@selector(doughnutChart:colorForSliceAtIndexPath:)]) {
        return [_delegate doughnutChart:self colorForSliceAtIndexPath:[NSIndexPath indexPathForSlice:index]];
    }
    return [UIColor colorWithHue:((index/8)%20)/20.0+0.02 saturation:(index%8+3)/10.0 brightness:91/100.0 alpha:1];
}

@end
