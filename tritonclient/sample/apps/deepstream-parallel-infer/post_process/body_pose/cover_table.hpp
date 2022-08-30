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
#pragma once

#include <memory>
#include <vector>

class CoverTable
{
public:
  CoverTable(int nrows, int ncols) : nrows(nrows), ncols(ncols)
  {
    rows.resize(nrows);
    cols.resize(ncols);
  }

  inline void coverRow(int row)
  {
    rows[row] = 1;
  }

  inline void coverCol(int col)
  {
    cols[col] = 1;
  }

  inline void uncoverRow(int row)
  {
    rows[row] = 0;
  }

  inline void uncoverCol(int col)
  {
    cols[col] = 0;
  }

  inline bool isCovered(int row, int col) const
  {
    return rows[row] || cols[col];
  }

  inline bool isRowCovered(int row) const
  {
    return rows[row];
  }

  inline bool isColCovered(int col) const
  {
    return cols[col];
  }

  inline void clear()
  {
    for (int i = 0; i < nrows; i++)
    {
      uncoverRow(i);
    }
    for (int j = 0; j < ncols; j++)
    {
      uncoverCol(j);
    }
  }

  const int nrows;
  const int ncols;

private:
  std::vector<bool> rows;
  std::vector<bool> cols;
};
