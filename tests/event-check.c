#include <windows.h>
#include <winevt.h>
int main(void) {
  SetLastError(0);
  EVT_HANDLE metadata=EvtOpenPublisherMetadata(NULL,L"UU-Isolated-Test-Missing-Provider",NULL,0,0);
  return metadata!=NULL || GetLastError()!=ERROR_EVT_PUBLISHER_METADATA_NOT_FOUND;
}
