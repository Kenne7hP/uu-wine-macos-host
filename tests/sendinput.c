#include <windows.h>
int main(void) {
    INPUT input[5]={0};
    int w=GetSystemMetrics(SM_CXSCREEN),h=GetSystemMetrics(SM_CYSCREEN);
    if(w<320 || h<240) return 2;
    input[0].type=INPUT_MOUSE;
    input[0].mi.dx=170*65535/(w-1);input[0].mi.dy=(h-130)*65535/(h-1);
    input[0].mi.dwFlags=MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE;
    input[1]=input[0];input[1].mi.dwFlags|=MOUSEEVENTF_LEFTDOWN;
    input[2]=input[0];input[2].mi.dwFlags|=MOUSEEVENTF_LEFTUP;
    input[3].type=INPUT_KEYBOARD;input[3].ki.wVk='A';
    input[4]=input[3];input[4].ki.dwFlags=KEYEVENTF_KEYUP;
    for(int i=0;i<5;i++) { if(SendInput(1,&input[i],sizeof(INPUT))!=1) return 3; Sleep(60); }
    return 0;
}
