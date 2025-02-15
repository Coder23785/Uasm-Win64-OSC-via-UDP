set appname=winsock2
set assembler="J:\Everything\Programming\compilers assemblers and tools\UASM\uasm257_x64\uasm64.exe"
set linker="J:\Everything\Programming\compilers assemblers and tools\MSVC\SEPT-2024\14.40.33807\bin\Hostx64\x64\link.exe" 
set rsrccompile="C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\rc.exe"
set _cvtres="J:\Everything\Programming\compilers assemblers and tools\MSVC\SEPT-2024\14.40.33807\bin\Hostx64\x64\cvtres.exe" 
%assembler% -win64 -archAVX -Zv8 -Zd -Sg -Zi8 -Fl=%appname%.lst -Fd=%appname%.importdef %appname%.asm
%rsrccompile% /v rsrc.rc
%_cvtres% /machine:x64 rsrc.res
%linker% /ENTRY:WinMainCrtStartup /PDB:%appname%.pdb /SUBSYSTEM:CONSOLE /DEBUG /INCREMENTAL:NO /LIBPATH:"J:\Everything\Programming\compilers assemblers and tools\MSVC\SEPT-2024\14.40.33807\lib\x64" %appname%.obj
echo "Remember to update the changelog!"

