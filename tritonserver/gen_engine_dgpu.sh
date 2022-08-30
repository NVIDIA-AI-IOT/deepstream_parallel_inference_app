#!/bin/bash
export PATH=$PATH:/usr/src/tensorrt/bin

trtexec --fp16 --onnx=./models/yolov4/1/yolov4_-1_3_416_416_dynamic.onnx.nms.onnx --saveEngine=./models/yolov4/1/yolov4_-1_3_416_416_dynamic.onnx_b32_gpu0.engine  --minShapes=input:1x3x416x416 --optShapes=input:16x3x416x416 --maxShapes=input:32x3x416x416 --shapes=input:16x3x416x416 --workspace=10000

wget --content-disposition 'https://api.ngc.nvidia.com/v2/resources/nvidia/tao/tao-converter/versions/v3.22.05_trt8.4_x86/files/tao-converter'
chmod 755 tao-converter

mkdir -p models/trafficcamnet/1/
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/resnet18_trafficcamnet_pruned.etlt' -O ./models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/trafficcamnet_int8.txt' -O ./models/trafficcamnet/1/trafficcamnet_int8.txt
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/trafficcamnet/versions/pruned_v1.0.2/files/labels.txt' -O ./models/trafficcamnet/labels.txt
./tao-converter -k tlt_encode -t int8 -c ./models/trafficcamnet/1/trafficcamnet_int8.txt -e ./models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt_b8_gpu0_int8.engine -b 8 -d 3,544,960 models/trafficcamnet/1/resnet18_trafficcamnet_pruned.etlt

mkdir -p models/US_LPD/1/
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lpdnet/versions/pruned_v1.0/files/usa_pruned.etlt' -O models/US_LPD/1/usa_pruned.etlt
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lpdnet/versions/pruned_v1.0/files/usa_lpd_cal.bin' -O models/US_LPD/1/usa_lpd_cal.bin
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lpdnet/versions/pruned_v1.0/files/usa_lpd_label.txt' -O models/US_LPD/usa_lpd_label.txt
./tao-converter -k nvidia_tlt -t int8 -c models/US_LPD/1/usa_lpd_cal.bin -e models/US_LPD/1/usa_pruned.etlt_b16_int8.engine -b 16 -d 3,480,640 models/US_LPD/1/usa_pruned.etlt

mkdir models/us_lprnet/1/
wget 'https://api.ngc.nvidia.com/v2/models/nvidia/tao/lprnet/versions/deployable_v1.0/files/us_lprnet_baseline18_deployable.etlt' -O models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt
./tao-converter -k nvidia_tlt -t fp16 -e models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt_b16_gpu0_fp16.engine -p image_input,1x3x48x96,8x3x48x96,16x3x48x96 models/us_lprnet/1/us_lprnet_baseline18_deployable.etlt

mkdir -p models/peoplenet/1/
wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/tao/peoplenet/versions/deployable_quantized_v2.6/files/resnet34_peoplenet_int8.etlt \
  -O models/peoplenet/1/resnet34_peoplenet_int8.etlt
wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/tao/peoplenet/versions/deployable_quantized_v2.6/files/resnet34_peoplenet_int8.txt \
  -O models/peoplenet/1/resnet34_peoplenet_int8.txt
wget --content-disposition https://api.ngc.nvidia.com/v2/models/nvidia/tao/peoplenet/versions/deployable_quantized_v2.6/files/labels.txt \
  -O models/peoplenet/labels.txt
./tao-converter -k tlt_encode -t int8 -c ./models/peoplenet/1/resnet34_peoplenet_int8.txt -e ./models/peoplenet/1/resnet34_peoplenet_int8.etlt_b8_gpu0_int8.engine -b 8 -d 3,544,960 models/peoplenet/1/resnet34_peoplenet_int8.etlt

#generate engine for vehicle related models.
echo "Building Model Primary_Detector..."	
mkdir -p models/Primary_Detector/1/
trtexec         --calib=/opt/nvidia/deepstream/deepstream/samples/models/Primary_Detector/cal_trt.bin         --deploy=/opt/nvidia/deepstream/deepstream/samples/models/Primary_Detector/resnet10.prototxt         --model=/opt/nvidia/deepstream/deepstream/samples/models/Primary_Detector/resnet10.caffemodel         --maxBatch=30         --saveEngine=models/Primary_Detector/1/resnet10.caffemodel_b30_gpu0_int8.engine         --buildOnly --output=conv2d_bbox --output=conv2d_cov/Sigmoid --int8

echo "Building Model Secondary_CarColor..."
mkdir -p models/Secondary_CarColor/1/
trtexec         --calib=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarColor/cal_trt.bin         --deploy=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarColor/resnet18.prototxt         --model=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarColor/resnet18.caffemodel         --maxBatch=16         --saveEngine=models/Secondary_CarColor/1/resnet18.caffemodel_b16_gpu0_int8.engine         --buildOnly --output=predictions/Softmax --int8
 
echo "Building Model Secondary_CarMake..."
mkdir -p models/Secondary_CarMake/1/
trtexec         --calib=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarMake/cal_trt.bin         --deploy=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarMake/resnet18.prototxt         --model=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_CarMake/resnet18.caffemodel         --maxBatch=16         --saveEngine=models/Secondary_CarMake/1/resnet18.caffemodel_b16_gpu0_int8.engine         --buildOnly --output=predictions/Softmax --int8
 
echo "Building Model Secondary_VehicleTypes..."
mkdir -p models/Secondary_VehicleTypes/1/
trtexec         --calib=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleTypes/cal_trt.bin         --deploy=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleTypes/resnet18.prototxt         --model=/opt/nvidia/deepstream/deepstream/samples/models/Secondary_VehicleTypes/resnet18.caffemodel         --maxBatch=16         --saveEngine=models/Secondary_VehicleTypes/1/resnet18.caffemodel_b16_gpu0_int8.engine         --buildOnly --output=predictions/Softmax --int8
echo "Finished generating engine files."
