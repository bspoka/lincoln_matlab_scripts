//==============================================================================
//
// Title:		picoquant_corr.h
// Purpose:		A short description of the interface.
//
// Created on:	9/29/2017 at 9:40:29 AM by bspoka.
// Copyright:	Microsoft. All Rights Reserved.
//
//==============================================================================

#ifndef __picoquant_corr_H__
#define __picoquant_corr_H__

#ifdef __cplusplus
    extern "C" {
#endif

//==============================================================================
// Include files

#include "cvidef.h"
#include <stdint.h> 
#include <ansi_c.h>
#include <math.h>
#include <stdlib.h>

//==============================================================================
// Constants

//==============================================================================
// Types
#define UINT32 uint32_t
#define UINT8 uint8_t 

//==============================================================================
// External variables

//==============================================================================
// Global functions

//void picoquant_generate_log_lags(double t_end, double coarseness, double *lag_bin_edges,
//									 double *lags, double *division_factor, int *num_lags);

void picoquant_parse_records(uint32_t *fifo_buffer, int fifo_size, double *photon_times, double *sync, UINT8 *channels,//
	int *photon_count, double *overflow, UINT8 device, UINT8 tmode);

void picoquant_get_arm_channels (UINT8 *channels, double *sync, double *times, int num_records, UINT8 *arm1_channels,  int arm1_num, UINT8 *arm2_channels,
	 int arm2_num, double *arm1, double *arm2, int *arm1_tally, int *arm2_tally);

void picoquant_photons_in_bins(double *ch1, double* ch2, int num_ch1, int num_ch2, double start_time_ps, 
							   double stop_time_ps, double coarseness, double offset_lag_ps, double *acf, double *lags, int *acf_length);

void picoquant_g2_corr(double *ch1, double* ch2, int num_ch1, int num_ch2, double ps_range, 
							   int num_points, double offset_lag_ps, double *acf, double *lags);

#ifdef __cplusplus
    }
#endif

#endif  /* ndef __picoquant_corr_H__ */
