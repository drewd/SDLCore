#import "VideoDecoder.h"
#import <AppKit/AppKit.h>

// Reference: https://github.com/niswegmann/H264Streamer

typedef enum {
    NALUTypeSliceNoneIDR = 1,
    NALUTypeSliceIDR = 5,
    NALUTypeSPS = 7,
    NALUTypePPS = 8
} NALUType;

static int naluType(uint8_t* nalu) { return nalu[4] & 0x1F; } // Check after included start code

static uint32_t nextNALU(uint8_t** ptr_inout, uint32_t length_in)
{
    uint32_t    sizeOfNalu = 0;
    uint32_t    remaining = length_in;
    uint8_t*    ptr = (*ptr_inout);
    uint8_t*    ptr_out = NULL;
    while (remaining > sizeof(uint32_t)) {
        if (ptr[0] == 0x00 && ptr[1] == 0x00 && ptr[2] == 0x00 && ptr[3] == 0x01) {
            // Found the start code
            // Include it as it will be rewritten to the big-endian length of the slice
            ptr_out = (uint8_t*)ptr;
            ptr += sizeof(uint32_t);
            sizeOfNalu = remaining; // assume it's the last one
            remaining -= sizeof(uint32_t);
            break;
        }
        ptr++;
        remaining -= sizeof(uint32_t);
    }
    if (ptr_out != NULL) {
        while (remaining > sizeof(uint32_t)) {
            if (ptr[0] == 0x00 && ptr[1] == 0x00 && ptr[2] == 0x00 && ptr[3] == 0x01) {
                // Found the start code of the NEXT NALU, end current NALU
                sizeOfNalu = (uint32_t)ptr - (uint32_t)ptr_out;
                break;
            }
            ptr++;
            remaining--;
        }
    }
    if (sizeOfNalu && ptr_out) {
        // Overwrite start code with big-endian length of the NALU 
        uint32_t dataLength32 = htonl (sizeOfNalu - 4);
        memcpy (ptr_out, &dataLength32, sizeof (uint32_t));
    }
    *ptr_inout = ptr_out;
    return sizeOfNalu;
}

@interface VideoDecoder()
@property (nonatomic, assign) CMVideoFormatDescriptionRef formatDesc;
@property (nonatomic, retain) AVSampleBufferDisplayLayer* videoLayer;
@property (nonatomic, assign) uint32_t spsSize;
@property (nonatomic, assign) uint32_t ppsSize;
@property (nonatomic, assign) uint8_t* spsData;
@property (nonatomic, assign) uint8_t* ppsData;
@property (nonatomic) BOOL videoFormatDescriptionAvailable;
@end

@implementation VideoDecoder

- (void)updateFormatDescriptionIfPossible {
    if (self.spsData != nil && self.ppsData != nil) {
        const uint8_t * const parameterSetPointers[2] = { self.spsData, self.ppsData };
        const size_t parameterSetSizes[2] = { self.spsSize, self.ppsSize };
        OSStatus __unused status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2,
                                                                              parameterSetPointers,
                                                                              parameterSetSizes,
                                                                              4,
                                                                              & _formatDesc
                                                                              );
        _videoFormatDescriptionAvailable = YES;
        //NSLog(@"Updated CMVideoFormatDescription. Creation: %@.", (status == noErr) ? @"successfully." : @"failed.");
    }
}

- (CMSampleBufferRef)handleFrame:(uint8_t*)frame length:(uint32_t)length
{
    if (self.videoFormatDescriptionAvailable) {
        
        // Create the video block
        CMBlockBufferRef videoBlock = NULL;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock( NULL,
                                                             (void *)frame,
                                                             length,
                                                             kCFAllocatorNull,
                                                             NULL,
                                                             0,
                                                             length,
                                                             0,
                                                             & videoBlock );
        //NSLog(@"BlockBufferCreation: %@", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
        
        // Create the CMSampleBuffer
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = { length };
        status = CMSampleBufferCreate(kCFAllocatorDefault,
                                      videoBlock,
                                      true,
                                      NULL,
                                      NULL,
                                      _formatDesc,
                                      1,
                                      0,
                                      NULL,
                                      1,
                                      sampleSizeArray,
                                      &sampleBuffer);
        
        //NSLog(@"SampleBufferCreate: %@", (status == noErr) ? @"successfully." : @"failed.");
        
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        
        return sampleBuffer;
    }
    return NULL;
}

-(void) receivedRawVideoFrame:(uint8_t *)packet withSize:(uint32_t)packetSize completion:(FrameDecoded)frameDecoded
{
#   define MAX_FRAME_SIZE   16384
    static uint8_t  frame[MAX_FRAME_SIZE];
    uint8_t*        pCurr = frame;
    uint32_t        frameLength = 0;
    
    uint32_t naluLength;
    uint32_t bufferLengthRemaining = packetSize;
    uint8_t* pNALU = packet;
    
    while (1) {
        naluLength = nextNALU(&pNALU, bufferLengthRemaining);
        if (naluLength) {
            int type = naluType(pNALU);
            //NSLog(@"Found NALU[type:%u] %u bytes: [0x%02X 0x%02X 0x%02X 0x%02X] [0x%02X 0x%02X 0x%02X 0x%02X] - [0x%02X 0x%02X 0x%02X 0x%02X]",
            //      type, naluLength,
            //      pNALU[0], pNALU[1], pNALU[2], pNALU[3],
            //      pNALU[4], pNALU[5], pNALU[6], pNALU[7],
            //      pNALU[naluLength-4], pNALU[naluLength-3],
            //      pNALU[naluLength-2], pNALU[naluLength-1]);
            switch (type) {
                case NALUTypeSliceNoneIDR:
                case NALUTypeSliceIDR:
                {
                    memcpy(pCurr, pNALU, naluLength);
                    frameLength += naluLength;
                    pCurr += naluLength;
                    break;
                }
                case NALUTypeSPS:
                    self.spsData = &pNALU[4]; // Drop start code
                    self.spsSize = naluLength - 4;
                    [self updateFormatDescriptionIfPossible];
                    break;
                case NALUTypePPS:
                    self.ppsData = &pNALU[4]; // Drop start code
                    self.ppsSize = naluLength - 4;
                    [self updateFormatDescriptionIfPossible];
                    break;
                default:
                    //NSLog(@"*** Ignoring NALU: %u ***", type);
                    break;
            }
        } else {
            CMSampleBufferRef sampleBuffer = [self handleFrame:frame length:frameLength];
            if ((sampleBuffer != nil) && (frameDecoded != nil)) {
                frameDecoded(sampleBuffer);
            }
            break;
        }
        pNALU += naluLength;
        bufferLengthRemaining -= naluLength;
    }
}

@end

