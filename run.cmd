if "%1" == "" goto none
goto continue

:none
echo Usage: run asmtcode
goto done

:continue

docker run -it --rm -v %cd%:/submission_src -v %~dp0:/tests  bjucps/cps301-test bash tests/rundocker.sh %1

:done