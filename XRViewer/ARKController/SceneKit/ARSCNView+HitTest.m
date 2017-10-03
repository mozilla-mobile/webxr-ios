#import "ARSCNView+HitTest.h"
#import "HitTestResult.h"

@implementation HitTestRay
@end


@implementation FeatureHitTestResult
@end


@implementation ARSCNView (HitTest)

- (NSArray *)hitTestPoint:(CGPoint)point withResult:(HitTestResultBlock)resultBlock
{
    // 1. Always do a hit test against exisiting plane anchors first.
    //    (If any such anchors exist & only within their extents.)
    
    NSArray *planeHitTestResult = [self hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    if ([planeHitTestResult count] > 0)
    {
        ARHitTestResult *result = [planeHitTestResult firstObject];
        
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)[result anchor];
        SCNVector3 planeHitTestPosition = SCNVector3Make(result.worldTransform.columns[3].x, result.worldTransform.columns[3].y, result.worldTransform.columns[3].z);
        
        HitTestResult *r = [HitTestResult new];
        [r setAnchor:planeAnchor];
        [r setPosition:planeHitTestPosition];
        [r setHightQuality:YES];
        
        resultBlock(r);
        
        return planeHitTestResult;
    }
    
    // -------------------------------------------------------------------------------
    // 2. Collect more information about the environment by hit testing against
    //    the feature point cloud, but do not return the result yet.
    
    NSArray *hightQualityFeatureHitTestResult = [self hitTestWithFeaturesWithPoint:point
                                                         coneOpeningAngleInDegrees:18
                                                                       minDistance:0.2
                                                                       maxDistance:2
                                                                        maxResults:1];
    
    SCNVector3 featureHitTestPosition = SCNVector3Zero;
    BOOL highQualityFeatureHitTestResult = NO;
    
    if ([hightQualityFeatureHitTestResult count] > 0)
    {
        FeatureHitTestResult *result = [hightQualityFeatureHitTestResult firstObject];
        featureHitTestPosition = [result position];
        highQualityFeatureHitTestResult = YES;
    }
    
    // -------------------------------------------------------------------------------
    // 3. If desired or necessary (no good feature hit test result): Hit test
    //    against an infinite, horizontal plane (ignoring the real world).
    /*BOOL useInfinite = NO;
    
    if (useInfinite || highQualityFeatureHitTestResult == NO)
    {
        SCNVector3 pointOnInfinitePlane = [self hitTestWithInfiniteHorizontalPlane:point pointOnPlane:[_focus position]];
        
        if (SCNVector3EqualToVector3(pointOnInfinitePlane, SCNVector3Zero))
        {
            //[_focus unhide];
            //[_focus updateForPosition:pointOnInfinitePlane planeAnchor:nil camera:[[[self session] currentFrame] camera]];
            
            //[self setHiTestResults:planeHitTestResult];
            
            resultBlock(YES, pointOnInfinitePlane, nil);
            
            return;
        }
    }*/
    
    // -------------------------------------------------------------------------------
    // 4. If available, return the result of the hit test against high quality
    //    features if the hit tests against infinite planes were skipped or no
    //    infinite plane was hit.
    
    if (highQualityFeatureHitTestResult)
    {
        HitTestResult *r = [HitTestResult new];
        [r setPosition:featureHitTestPosition];
        [r setHightQuality:YES];
        
        resultBlock(r);
        
        return planeHitTestResult;
    }
    
    
    // -------------------------------------------------------------------------------
    // 5. As a last resort, perform a second, unfiltered hit test against features.
    //    If there are no features in the scene, the result returned here will be nil.
    
    NSArray *unfilteredFeatureHitTestResults = [self hitTestWithFeaturesWithPoint:point];
    
    if ([unfilteredFeatureHitTestResults count] > 0)
    {
        FeatureHitTestResult *result = [unfilteredFeatureHitTestResults firstObject];
            
        HitTestResult *r = [HitTestResult new];
        [r setPosition:[result position]];
        [r setHightQuality:NO];
        
        resultBlock(r);
        
        return planeHitTestResult;
    }
    
    resultBlock(nil);
    
    return planeHitTestResult;
}

- (HitTestRay *)hitTestRayFromScreenPosition:(CGPoint)position
{
    ARFrame *currentFrame = [[self session] currentFrame];
    
    SCNVector3 cameraPos = SCNVector3Make([[currentFrame camera] transform].columns[3].x, [[currentFrame camera] transform].columns[3].y, [[currentFrame camera] transform].columns[3].z);
    
    // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
    SCNVector3 positionVec = SCNVector3Make(position.x, position.y, 1);
    SCNVector3 screenPosOnFarClippingPlane = [self unprojectPoint:positionVec];
    
    SCNVector3 rayDirection = SCNVector3Make(screenPosOnFarClippingPlane.x - cameraPos.x, screenPosOnFarClippingPlane.y - cameraPos.y, screenPosOnFarClippingPlane.z - cameraPos.z);
    rayDirection = [self normalizeVector:rayDirection];
    
    HitTestRay *ray = [HitTestRay new];
    [ray setOrigin:cameraPos];
    [ray setDirection:rayDirection];
    
    return ray;
}

- (SCNVector3)hitTestWithInfiniteHorizontalPlane:(CGPoint)point pointOnPlane:(SCNVector3)pointOnPlane
{
    HitTestRay *ray = [self hitTestRayFromScreenPosition:point];
    
    if (ray == nil)
    {
        return SCNVector3Zero;
    }
    
    // Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
    if ([ray direction].y > -0.03)
    {
        return SCNVector3Zero;
    }
    
    // Return the intersection of a ray from the camera through the screen position with a horizontal plane
    // at height (Y axis).
    return [self rayIntersectionWithHorizontalPlaneWithOrigin:ray.origin direction:ray.direction planeY:pointOnPlane.y];
}

- (SCNVector3)rayIntersectionWithHorizontalPlaneWithOrigin:(SCNVector3)rayOrigin direction:(SCNVector3)theDirection planeY:(CGFloat)planeY
{
    SCNVector3 direction = [self normalizeVector:theDirection];
    
    if (direction.y == 0)
    {
        if (rayOrigin.y == planeY)
        {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.
            return rayOrigin;
        }
        // The ray is parallel to the plane and never intersects.
        return SCNVector3Zero;
    }
    
    // The distance from the ray's origin to the intersection point on the plane is:
    //   (pointOnPlane - rayOrigin) dot planeNormal
    //  --------------------------------------------
    //          direction dot planeNormal
    
    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    CGFloat dist = (planeY - rayOrigin.y) / direction.y;
    
    // Do not return intersections behind the ray's origin.
    if (dist < 0)
    {
        return SCNVector3Zero;
    }
    
    // Return the intersection point.
    return SCNVector3Make(rayOrigin.x + (direction.x * dist), rayOrigin.y + (direction.y * dist), rayOrigin.z + (direction.z * dist));
}

- (NSArray *)hitTestWithFeaturesWithPoint:(CGPoint)point coneOpeningAngleInDegrees:(CGFloat)coneOpeningAngleInDegrees minDistance:(CGFloat)minDistance maxDistance:(CGFloat)maxDistance maxResults:(NSUInteger)maxResults
{
    NSMutableArray *results = [NSMutableArray new];
    
    ARPointCloud *features = [[[self session] currentFrame] rawFeaturePoints];
    
    if (features == nil)
    {
        return results;
    }
    
    HitTestRay *ray = [self hitTestRayFromScreenPosition:point];
    
    if (ray == nil)
    {
        return results;
    }
    
    CGFloat maxAngleInDeg = fmin(coneOpeningAngleInDegrees, 360) / 2;
    CGFloat maxAngle = ((maxAngleInDeg / 180) * M_PI);
    
    vector_float3 *points = (vector_float3 *)[features points];
    
    for (int i = 0; i < [features count]; i++)
    {
        vector_float3 point = points[i];
        
        SCNVector3 featurePos = SCNVector3FromFloat3(point);
        
        SCNVector3 originToFeature = SCNVector3Make(featurePos.x - ray.origin.x, featurePos.y - ray.origin.y, featurePos.z - ray.origin.z);
        
        SCNVector3 crossProduct = [self vector:originToFeature crossWithVector:[ray direction]];
        
        CGFloat featureDistanceFromResult = [self lengthVector:crossProduct];
        
        CGFloat dot = [self vector:[ray direction] dotVector:originToFeature];
        
        SCNVector3 hitTestResult = SCNVector3Make(ray.origin.x + (ray.direction.x * dot),
                                                  ray.origin.y + (ray.direction.y * dot),
                                                  ray.origin.z + (ray.direction.z * dot));
        
        CGFloat hitTestResultDistance = [self lengthVector:SCNVector3Make(hitTestResult.x - ray.origin.x,
                                                                          hitTestResult.y - ray.origin.y,
                                                                          hitTestResult.z - ray.origin.z)];
        
        if (hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance)
        {
            // Skip this feature - it is too close or too far away.
            continue;
        }
        
        SCNVector3 originToFeatureNormalized = [self normalizeVector:originToFeature];
        
        CGFloat angleBetweenRayAndFeature = acosf([self vector:[ray direction] dotVector:originToFeatureNormalized]);
        
        if (angleBetweenRayAndFeature > maxAngle)
        {
            // Skip this feature - is is outside of the hit test cone.
            continue;
        }
        
        // All tests passed: Add the hit against this feature to the results.
        FeatureHitTestResult *r = [FeatureHitTestResult new];
        [r setPosition:hitTestResult];
        [r setDistanceToRayOrigin:hitTestResultDistance];
        [r setFeatureHit:featurePos];
        [r setFeatureDistanceToHitResult:featureDistanceFromResult];
        
        [results addObject:r];
    }
    
    // Sort the results by feature distance to the ray.
    NSArray *sortedResults = [results sortedArrayUsingComparator:^NSComparisonResult(FeatureHitTestResult *  _Nonnull obj1, FeatureHitTestResult *  _Nonnull obj2)
    {
        if (obj1.distanceToRayOrigin < obj2.distanceToRayOrigin)
        {
            return NSOrderedDescending;
        }
        
        return NSOrderedAscending;
    }];
    
    // Cap the list to maxResults.
    NSMutableArray *cappedResults = [NSMutableArray arrayWithCapacity:[sortedResults count]];
    NSUInteger i = 0;
    
    while (i < maxResults && i < [sortedResults count])
    {
        [cappedResults addObject:sortedResults[i]];
        i++;
    }
    
    return [cappedResults copy];
}

- (NSArray *)hitTestWithFeaturesWithPoint:(CGPoint)point
{
    NSMutableArray *results = [NSMutableArray new];
    
    HitTestRay *ray = [self hitTestRayFromScreenPosition:point];
    
    if (ray == nil)
    {
        return results;
    }
    
    FeatureHitTestResult *result = [self hitTestFromOrigin:ray.origin direction:ray.direction];
    
    if (result)
    {
        [results addObject:result];
    }
    
    return results;
    
}

- (FeatureHitTestResult *)hitTestFromOrigin:(SCNVector3)origin direction:(SCNVector3)direction
{
    ARPointCloud *features = [[[self session] currentFrame] rawFeaturePoints];
    
    if (features == nil)
    {
        return nil;
    }
    
    vector_float3 *points = (vector_float3 *)[features points];
    
    // Determine the point from the whole point cloud which is closest to the hit test ray.
    SCNVector3 closestFeaturePoint = origin;
    CGFloat minDistance = FLT_MAX;
    
    for (int i = 0; i < [features count]; i++)
    {
        vector_float3 point = points[i];
        
        SCNVector3 featurePos = SCNVector3FromFloat3(point);
        
        SCNVector3 originVector = SCNVector3Make(origin.x - featurePos.x, origin.y - featurePos.y, origin.z - featurePos.z);
        SCNVector3 crossProduct = [self vector:originVector crossWithVector:direction];
        CGFloat featureDistanceFromResult = [self lengthVector:crossProduct];
        
        if (featureDistanceFromResult < minDistance)
        {
            closestFeaturePoint = featurePos;
            minDistance = featureDistanceFromResult;
        }
    }
        
    // Compute the point along the ray that is closest to the selected feature.
    SCNVector3 originToFeature = SCNVector3Make(closestFeaturePoint.x - origin.x, closestFeaturePoint.y - origin.y, closestFeaturePoint.z - origin.z);
    CGFloat dot = [self vector:direction dotVector:originToFeature];
    
    SCNVector3 hitTestResult = SCNVector3Make(origin.x + (direction.x * dot),
                                              origin.y + (direction.y * dot),
                                              origin.z + (direction.z * dot));
    
    SCNVector3 dictanceVector = SCNVector3Make(hitTestResult.x - origin.x, hitTestResult.y - origin.y, hitTestResult.z - origin.z);
    CGFloat hitTestResultDistance = [self lengthVector:dictanceVector];
    
    FeatureHitTestResult *result = [FeatureHitTestResult new];
    [result setFeatureDistanceToHitResult:minDistance];
    [result setFeatureHit:closestFeaturePoint];
    [result setDistanceToRayOrigin:hitTestResultDistance];
    [result setPosition:hitTestResult];
    
    return result;
}

#pragma mark

- (SCNVector3)normalizeVector:(SCNVector3)vector
{
    CGFloat length = [self lengthVector:vector];
    
    if (length == 0)
    {
        return vector;
    }
    
    return SCNVector3Make(vector.x / length, vector.y / length, vector.z / length);
}

- (CGFloat)lengthVector:(SCNVector3)vector
{
    return sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z);
}

- (SCNVector3)vector:(SCNVector3)vector crossWithVector:(SCNVector3)crossVector
{
    return SCNVector3Make(vector.y * crossVector.z - vector.z * crossVector.y,
                          vector.z * crossVector.x - vector.x * crossVector.z,
                          vector.x * crossVector.y - vector.y * crossVector.x);
}

- (CGFloat)vector:(SCNVector3)vector dotVector:(SCNVector3)dotVector
{
    return (vector.x * dotVector.x) + (vector.y * dotVector.y) + (vector.z * dotVector.z);
}

@end
