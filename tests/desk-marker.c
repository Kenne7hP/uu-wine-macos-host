typedef void *Handle;
typedef unsigned long Color;
__declspec(dllimport) Handle GetDC(Handle);
__declspec(dllimport) int GetSystemMetrics(int);
__declspec(dllimport) int ReleaseDC(Handle, Handle);
__declspec(dllimport) Handle CreateCompatibleDC(Handle);
__declspec(dllimport) Handle CreateCompatibleBitmap(Handle,int,int);
__declspec(dllimport) Handle SelectObject(Handle,Handle);
__declspec(dllimport) int BitBlt(Handle,int,int,int,int,Handle,int,int,unsigned long);
__declspec(dllimport) Color GetPixel(Handle,int,int);
__declspec(dllimport) void ExitProcess(unsigned int);
__declspec(dllimport) void Sleep(unsigned);
void entry(void) {
  int w=GetSystemMetrics(0), h=GetSystemMetrics(1);
  Handle screen=GetDC(0), dc=CreateCompatibleDC(screen);
  Handle bitmap=CreateCompatibleBitmap(screen,w,h);
  if(!dc || !bitmap || !screen || w<32 || h<32) ExitProcess(10);
  SelectObject(dc,bitmap);
  unsigned marked=0, changes=0, prior=0;
  for(int attempt=0;attempt<150;attempt++) {
    Sleep(60);
    if(!BitBlt(dc,0,0,360,110,screen,32,85,0x00CC0020)) ExitProcess(11);
    unsigned code=0, motion=0;
    for(int i=0;i<24;i++) code=(code<<1)|((GetPixel(dc,13+i*10,21)&255)<128);
    for(int x=6;x<323;x++) if ((GetPixel(dc,x,95)&255)<180) motion+=x;
    if(code==0xd3ac90) {
      marked++;
      if(prior && prior!=motion) changes++;
      prior=motion;
    }
    if(marked>=20 && changes>=4) ExitProcess(0);
  }
  ExitProcess(marked<20?13:14);
}
