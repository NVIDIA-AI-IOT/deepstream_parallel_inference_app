/*
 * SPDX-FileCopyrightText: Copyright (c) <2022> NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <unordered_map>
#include "nvdsinfer_custom_impl.h"

static const int NUM_CLASSES_YOLO = 80;

float clamp(const float val, const float minVal, const float maxVal)
{
    assert(minVal <= maxVal);
    return std::min(maxVal, std::max(minVal, val));
}

extern "C" bool NvDsInferParseCustomYoloV4(
    std::vector<NvDsInferLayerInfo> const& outputLayersInfo,
    NvDsInferNetworkInfo const& networkInfo,
    NvDsInferParseDetectionParams const& detectionParams,
    std::vector<NvDsInferParseObjectInfo>& objectList);

extern "C" bool NvDsInferParseCustomYoloV4(
    std::vector<NvDsInferLayerInfo> const& outputLayersInfo,
    NvDsInferNetworkInfo const& networkInfo,
    NvDsInferParseDetectionParams const& detectionParams,
    std::vector<NvDsInferParseObjectInfo>& objectList)
{
    if (NUM_CLASSES_YOLO != detectionParams.numClassesConfigured)
    {
        std::cerr << "WARNING: Num classes mismatch. Configured:"
                  << detectionParams.numClassesConfigured
                  << ", detected by network: " << NUM_CLASSES_YOLO << std::endl;
    }

    std::vector<NvDsInferParseObjectInfo> objects;
    uint num_bboxes;
    float *score_buffer;
    float *bbox_buffer;
    
    
    for (int i=0; i<outputLayersInfo.size(); i++) {
        if (!strcmp(outputLayersInfo[i].layerName, "nmsed_boxes")) {
            const NvDsInferLayerInfo &boxes = outputLayersInfo[i];
            num_bboxes = boxes.inferDims.d[0];
            bbox_buffer = (float *)boxes.buffer;
        }
        else if (!strcmp(outputLayersInfo[i].layerName, "nmsed_scores")) {
            const NvDsInferLayerInfo &scores = outputLayersInfo[i];
            score_buffer = (float *)scores.buffer;
        }
    }

    for (int n=0; n<num_bboxes; n++) {
        NvDsInferParseObjectInfo outObj;
        if(score_buffer[n] > 0.1) {
            outObj.left = bbox_buffer[n*4] * networkInfo.width;
            outObj.top = bbox_buffer[n*4+1] * networkInfo.height;
            outObj.width = (bbox_buffer[n*4+2]-bbox_buffer[n*4]) * networkInfo.width;
            outObj.height = (bbox_buffer[n*4+3]-bbox_buffer[n*4+1]) * networkInfo.height;
            outObj.classId=n;
            outObj.detectionConfidence=score_buffer[n];
            objectList.push_back(outObj);
        }       
    }

    return true;
}
/* YOLOv4 implementations end*/


/* Check that the custom function has been defined correctly */
CHECK_CUSTOM_PARSE_FUNC_PROTOTYPE(NvDsInferParseCustomYoloV4);
