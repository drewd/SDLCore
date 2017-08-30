
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^FrameDecoded)(CMSampleBufferRef sampleBuffer);

@interface VideoDecoder: NSObject
- (void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize completion:(FrameDecoded)completion;
@end
