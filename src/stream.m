#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <IOSurface/IOSurface.h>
#include <fcntl.h>
#include <stdatomic.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include "frame-protocol.h"

int main(int argc, char **argv) {
    if (argc != 2 || !CGPreflightScreenCaptureAccess()) return 2;
    CGDirectDisplayID display = CGMainDisplayID();
    CGRect bounds = CGDisplayBounds(display);
    unsigned width = bounds.size.width, height = bounds.size.height;
    size_t pitch = width*4, slot = 8 + pitch*height;
    size_t size = UURF_HEADER_BYTES + UURF_SLOT_COUNT*slot;
    int fd = open(argv[1], O_CREAT|O_EXCL|O_RDWR, 0600);
    if (fd < 0 || ftruncate(fd,size)) return 3;
    unsigned char *map = mmap(NULL,size,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    if (map == MAP_FAILED) return 4;
    uint32_t *header = (void*)map;
    header[0]=UURF_MAGIC; header[1]=UURF_VERSION; header[2]=width; header[3]=height;
    header[4]=pitch; header[5]=1; header[9]=1;
    struct uurf_monitor_layout layout = {0,0,width,height,0,0,width,height,width,height};
    *(struct uurf_monitor_layout*)(map+UURF_BASE_HEADER_BYTES)=layout;
    dispatch_queue_t queue = dispatch_queue_create("uu.desktop.capture", DISPATCH_QUEUE_SERIAL);
    __block uint64_t count = 0;
    NSDictionary *options = @{(__bridge NSString *)kCGDisplayStreamMinimumFrameTime:@(1./15.)};
    CGDisplayStreamRef stream = CGDisplayStreamCreateWithDispatchQueue(display,width,height,kCVPixelFormatType_32BGRA,
      (__bridge CFDictionaryRef)options,queue,^(CGDisplayStreamFrameStatus status,uint64_t time,IOSurfaceRef image,CGDisplayStreamUpdateRef update) {
        if(status!=kCGDisplayStreamFrameStatusFrameComplete || !image ||
           IOSurfaceGetWidth(image)!=width || IOSurfaceGetHeight(image)!=height ||
           IOSurfaceGetBytesPerRow(image)<pitch || IOSurfaceLock(image,kIOSurfaceLockReadOnly,NULL)) return;
        size_t src_pitch=IOSurfaceGetBytesPerRow(image);
        const unsigned char *src=IOSurfaceGetBaseAddress(image);
        if(src) {
            uint64_t n=count+1;
            unsigned char *dest=map+uurf_slot_offset(n,slot);
            _Atomic uint64_t *seq=(void *)dest;
            atomic_store(seq,2*n-1);
            if(src_pitch==pitch) memcpy(dest+8,src,pitch*height);
            else for(size_t y=0;y<height;y++) memcpy(dest+8+y*pitch,src+y*src_pitch,pitch);
            atomic_store(seq,2*n);
            atomic_store((_Atomic uint64_t*)(map+24),n);
            count=n;
        }
        IOSurfaceUnlock(image,kIOSurfaceLockReadOnly,NULL);
      });
    if(!stream || CGDisplayStreamStart(stream)) return 6;
    for(;;) pause();
}
