#!/bin/bash

IS_JETSON_PLATFORM=`uname -i | grep aarch64`

export PATH=$PATH:/usr/src/tensorrt/bin

trtexec --fp16 --onnx=./models/yolov4/1/yolov4_-1_3_416_416_dynamic.onnx.nms.onnx --saveEngine=./models/yolov4/1/yolov4_-1_3_416_416_dynamic.onnx_b32_gpu0.engine  --minShapes=input:1x3x416x416 --optShapes=input:16x3x416x416 --maxShapes=input:32x3x416x416 --shapes=input:16x3x416x416 --workspace=10000

if [ ! ${IS_JETSON_PLATFORM} ]; then
    wget --content-disposition 'https://api.ngc.nvidia.com/v2/resources/org/nvidia/team/tao/tao-converter/v5.1.0_8.6.3.1_x86/files?redirect=true&path=tao-converter' -O tao-converter
else
    wget --content-disposition 'https://api.ngc.nvidia.com/v2/resources/org/nvidia/team/tao/tao-converter/v5.1.0_jp6.0_aarch64/files?redirect=true&path=tao-converter' -O tao-converter
fi
chmod 755 tao-converter

mkdir -p models/trafficcamnet/1/
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/resnet18_trafficcamnet_pruned.etlt' -O ./models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/trafficcamnet_int8.txt' -O ./models/trafficcamnet/1/trafficcamnet_int8.txt
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/labels.txt' -O ./models/trafficcamnet/labels.txt
./tao-converter -k tlt_encode -t int8 -c ./models/trafficcamnet/1/trafficcamnet_int8.txt -e ./models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt_b8_gpu0_int8.engine -b 8 -d 3,544,960 models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt

mkdir -p models/US_LPD/1/
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/lpdnet/pruned_v2.2/files?redirect=true&path=LPDNet_usa_pruned_tao5.onnx' -O models/US_LPD/1/LPDNet_usa_pruned_tao5.onnx
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/lpdnet/pruned_v2.2/files?redirect=true&path=usa_cal_8.6.1.bin' -O models/US_LPD/1/usa_cal_8.6.1.bin
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/lpdnet/pruned_v2.2/files?redirect=true&path=usa_cal_8.5.3.bin' -O models/US_LPD/1/usa_cal_8.5.3.bin
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lpdnet/versions/pruned_v1.0/files/usa_lpd_label.txt' -O models/US_LPD/usa_lpd_label.txt
trtexec --onnx=models/US_LPD/1/LPDNet_usa_pruned_tao5.onnx --int8 --calib=models/US_LPD/1/usa_cal_8.6.1.bin \
 --saveEngine=models/US_LPD/1//LPDNet_usa_pruned_tao5.onnx_b16_gpu0_int8.engine --minShapes="input_1:0":1x3x480x640 \
 --optShapes="input_1:0":16x3x480x640 --maxShapes="input_1:0":16x3x480x640

mkdir models/us_lprnet/1/
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lprnet/versions/deployable_v1.0/files/us_lprnet_baseline18_deployable.etlt' -O models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt
./tao-converter -k nvidia_tlt -t fp16 -e models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt_b16_gpu0_fp16.engine -p image_input,1x3x48x96,8x3x48x96,16x3x48x96 models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt

mkdir -p models/peoplenet/1/
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/peoplenet/pruned_quantized_decrypted_v2.3.3/files?redirect=true&path=resnet34_peoplenet_int8.onnx' \
  -O models/peoplenet/1/resnet34_peoplenet_int8.onnx
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/peoplenet/pruned_quantized_decrypted_v2.3.3/files?redirect=true&path=resnet34_peoplenet_int8.txt' \
  -O models/peoplenet/1/resnet34_peoplenet_int8.txt
wget --content-disposition 'https://api.ngc.nvidia.com/v2/models/org/nvidia/team/tao/peoplenet/pruned_quantized_decrypted_v2.3.3/files?redirect=true&path=labels.txt' \
 -O models/peoplenet/labels.txt
trtexec --onnx=./models/peoplenet/1/resnet34_peoplenet_int8.onnx --int8 \
 --calib=./models/peoplenet/1/resnet34_peoplenet_int8.txt --saveEngine=./models/peoplenet/1/resnet34_peoplenet_int8.onnx_b8_gpu0_int8.engine \
 --minShapes="input_1:0":1x3x544x960 --optShapes="input_1:0":8x3x544x960 --maxShapes="input_1:0":8x3x544x960

#generate engine for vehicle related models.
echo "Building Model Secondary_CarMake..."
mkdir -p models/Secondary_CarMake/1/
./tao-converter -k tlt_encode -t int8 -c /opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleMake/cal_trt.bin -e models/Secondary_CarMake/1/resnet18_vehiclemakenet.etlt_b16_gpu0_int8.engine -b 16 -d 3,244,244 /opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleMake/resnet18_vehiclemakenet.etlt

echo "Building Model Secondary_VehicleTypes..."
mkdir -p models/Secondary_VehicleTypes/1/
 ./tao-converter -k tlt_encode -t int8 -c /opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleTypes/cal_trt.bin -e ./models/Secondary_VehicleTypes/1/resnet18_vehicletypenet.etlt_b16_gpu0_int8.engine -b 16 -d 3,244,244 /opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleTypes/resnet18_vehicletypenet.etlt
echo "Finished generating engine files."
