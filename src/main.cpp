#include <string>
#include <volk.h>
#include <windows.h>

int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
{
	if (volkInitialize() != VK_SUCCESS)
	{
		MessageBoxA(nullptr, "volkInitialize failed: no Vulkan driver (vulkan-1.dll) found.", "Helfire_GE", MB_OK | MB_ICONERROR);
		return 1;
	}

	return 0;
}