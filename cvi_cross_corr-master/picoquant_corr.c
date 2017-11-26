#include "picoquant_corr.h"

//==============================================================================
//
// Title:		picoquant_corr.c
// Purpose:		A short description of the implementation.
//
// Created on:	9/29/2017 at 9:40:29 AM by bspoka.
// Copyright:	Microsoft. All Rights Reserved.
//
//==============================================================================

//==============================================================================
// Include files

//#include "picoquant_corr.h"

//==============================================================================
// Constants

//==============================================================================
// Types

//#define UINT32 uint32_t
//#define UINT8 uint8_t 

//==============================================================================
// Static global variables

//==============================================================================
// Static functions

//==============================================================================
// Global variables

//==============================================================================
// Global functions

/// HIFN  What does your function do?
/// HIPAR x/What inputs does your function expect?
/// HIRET What does your function return?


//generates logaithmically spaced lag bins
void generate_logspaced_lag_bins(int n_edges, double coarseness, double *lag_bin_edges) {

	double multiplier = 0;

	for (int j = 1; j <= n_edges; j++) {
		if (j == 1)
			lag_bin_edges[j - 1] = 1;
		else {
			multiplier = pow(2, floor((j - 1) / coarseness));
			lag_bin_edges[j - 1] = lag_bin_edges[j - 2] + multiplier;
		}
	}

}

void picoquant_parse_records(UINT32 *fifo_buffer, int fifo_size, double *photon_times, double *sync, UINT8 *channels,//
	int *photon_count, double *overflow, UINT8 device, UINT8 tmode) {

	UINT32 curr_record;
	UINT32 special;
	UINT32 dtime;
	UINT32 channel;
	int total_photons = 0;
	double overflow_correction = *overflow; //starting overflow 

	if (device == 0) { //Hydraharp
		if (tmode == 2) { // Hydraharp T2 mode
			for (int ind = 0; ind < fifo_size; ind++)
			{
				curr_record = fifo_buffer[ind];
				special = (curr_record >> 31) & 1;
				dtime = curr_record & 33554431;
				channel = (curr_record >> 25) & 63;

				double timetag = overflow_correction + dtime;

				if (special == 0) { //normal photon record
					photon_times[total_photons] = timetag;
					channels[total_photons] = (UINT8)channel;
					total_photons++;
				}
				else {
					if (channel == 63) { //overflow record
						if (dtime == 0)
							overflow_correction += 33554432;
						else
							overflow_correction += 33554432 * dtime;
					}
				}

			}
		}

		if (tmode == 3) {// Hydraharp T3 mode
			UINT32 nsync;
			for (int ind = 0; ind <fifo_size; ind++)
			{
				curr_record = fifo_buffer[ind];
				special = (curr_record >> 31) & 1;
				dtime = (curr_record >> 10) & 32767;
				channel = (curr_record >> 25) & 63;
				nsync = curr_record & 1023;

				if (special == 0) { //normal photon record
					photon_times[total_photons] = dtime;
					channels[total_photons] = (UINT8)channel;
					sync[total_photons] = overflow_correction + nsync;
					total_photons++;
				}
				else {
					if (channel == 63) { //overflow record
						if (nsync == 0)
							overflow_correction += 1024;
						else
							overflow_correction += 1024 * nsync;
					}

				}
			}

		}

		if (device == 1) { //picoharp
			if (tmode == 2) { // picoharp T2 mode
				for (int ind = 0; ind < fifo_size; ind++)
				{
					curr_record = fifo_buffer[ind];
					dtime = curr_record & 268435455;
					channel = (curr_record >> 28) & 15;
					double timetag = overflow_correction + dtime;

					if ((channel >= 0) && (channel <= 4)) // normal record
					{
						photon_times[total_photons] = timetag;
						channels[total_photons] = (UINT8)channel;
						total_photons++;
					}
					else
					{
						if (channel == 15) {
							UINT32 markers = curr_record & 15;
							if (markers == 0)
								overflow_correction += 210698240;
						}
					}
				}

			}

			if (tmode == 3) { //Picoharp T3 mode
				UINT32 nsync;
				for (int ind = 0; ind < fifo_size; ind++)
				{
					curr_record = fifo_buffer[ind];
					dtime = (curr_record >> 16) & 4095;
					channel = (curr_record >> 28) & 15;
					nsync = curr_record & 65535;

					if ((channel >= 1) && (channel <= 4)) { //normal record
						photon_times[total_photons] = dtime;
						channels[total_photons] = (UINT8)channel;
						sync[total_photons] = overflow_correction + nsync;
					}
					else {
						if (channel == 15) {
							UINT32 markers = (curr_record >> 16) & 15;
							if (markers == 0)
								overflow_correction += 65536; //overflow
						}
					}

				}
			}
		}

		*photon_count = total_photons;
		*overflow = overflow_correction;
	}
}

void picoquant_get_arm_channels (UINT8 *channels, double *sync, double *times, int num_records, UINT8 *arm1_channels,  int arm1_num, UINT8 *arm2_channels,
	 int arm2_num, double *arm1, double *arm2, int *arm1_tally, int *arm2_tally) {

	// The output of the picoquant_parse_records function spits out an array of channel #s, sync counts and photon arrival times for ALL hydraharp channels. If one wants to cross-correlate 
	// certain channels, they have to be separated from the stream. Sometimes one wants to cross-correlate sums of more than one channel i.e. cross [ch0+ch1] with [ch2+ch3]. This function allows
	// to specify two arrays of chanels say [0, 1] and [2, 3] and the function spits out two arrays correpsonding to the arrival times of those channels. 

	//----------------Inputs---------------------------------------//
	// UINT8 *channels : pointer to the array of hydraharp channels (from picoquant_parse_records function)
	// UINT64 *sync : pointer to an array of sync counts (if data is T3)
	// UINT64 *times : photon arrival times in ps (macro arrival times if in T2, relative to the last pulse if in T3)
	// const int num_records : number of photon records
	// UINT8 *arm1_channels : pointer to the first array of channels to be separated from the photon stream
	// int arm1_num : number of channels in the above array
	// UINT8 *arm2_channels : pointer to the second array of channels to be separated from the photon stream
	// int arm2_num : number of channels in the above array

	//----------------Outputs---------------------------------------//
	// UINT64 *arm1 : array containing arrival times of channels specified by UINT8 *arm1_channels. 
	// UINT64 *arm2 : array containing arrival times of channels specified by UINT8 *arm2_channels. 
	// int *arm1_tally : total number of arrival times in arm1
	// int *arm2_tally : total number of arrival times in arm2

	int arm1_total = 0;
	int arm2_total = 0;

	UINT8 curr_channel;

	//loops through all of the photon records  and picks out only
	//those records that the user specified in the arm#_channels arrays
	for (int ind = 0; ind < num_records; ind++) {
		curr_channel = channels[ind]; //channel of each photon record

		//checks the first set of channels
		for (int arm1_ind = 0; arm1_ind < arm1_num; arm1_ind++) {
			if (curr_channel == arm1_channels[arm1_ind]) {
				arm1[arm1_total] = times[ind]; //if channels match the corresponding arrival time is selected
				arm1_total++;
				break;
			}
		}

		//checks the second set of channels
		for (int arm2_ind = 0; arm2_ind < arm2_num; arm2_ind++) {
			if (curr_channel == arm2_channels[arm2_ind]) {
				arm2[arm2_total] = times[ind];
				arm2_total++;
				break;
			}
		}
			
	}

	*arm1_tally = arm1_total;
	*arm2_tally = arm2_total;

}

void picoquant_photons_in_bins(double *ch1, double* ch2, int num_ch1, int num_ch2, double start_time_ps, 
							   double stop_time_ps, double coarseness, double offset_lag_ps, double *acf, double *lags, int *acf_bounds) {
	
	//this routine calculates the unnormalized cross-correlation function between arrival times in ch1 and ch2 arrays.
	double cascade_start = floor(log(start_time_ps)/log(2));
	double cascade_end = floor(log(stop_time_ps)/log(2));
	int num_edges = (int) cascade_end*coarseness;
	 
	if ((num_ch1 > 0) && (num_ch2 > 0))
	{ 
		
		double* lag_bin_edges = (double*)calloc(num_edges, sizeof(double)); //array for lag bins
		generate_logspaced_lag_bins(num_edges, coarseness, lag_bin_edges);
	
		int* low_inds = (int*)calloc(num_edges, sizeof(int)); //index of the earlies photon in each bin
		int* max_inds = (int*)calloc(num_edges, sizeof(int)); //index of the last photon in each bin
		double* bin_edges = (double*)calloc(num_edges, sizeof(double));
	
	    int curr_low, curr_max;
		double curr_acf;
	
	//for each photon in ch1
		for (int phot_ind = 0; phot_ind < num_ch1; phot_ind++) {

			//shift the lags for each photon
			for (int edge_ind = 0; edge_ind < num_edges; edge_ind++) {
				bin_edges[edge_ind] = ch1[phot_ind] + lag_bin_edges[edge_ind] + offset_lag_ps;
			}

			for (int k = (int)(cascade_start*coarseness); k < (num_edges - 1); k++) {

				curr_low = low_inds[k];
				while (low_inds[k] < num_ch2 && ch2[curr_low] < bin_edges[k]) {
					low_inds[k] = curr_low + 1;
					curr_low = low_inds[k];
				}

				curr_max = max_inds[k];
				while (max_inds[k] < num_ch2 && ch2[curr_max] <= bin_edges[k + 1]) {
					max_inds[k] = curr_max + 1;
					curr_max = max_inds[k];
				}

				low_inds[k + 1] = max_inds[k];
				curr_acf = acf[k];
				acf[k] = curr_acf + (max_inds[k] - low_inds[k]);

			}
		}
	
		//----------------Normalization---------------------------///
		double ch1_max = ch1[num_ch1-1];
		double ch2_max = ch2[num_ch2-1];
		double ch1_ch2_ratio = (num_ch1/ch1_max)*(num_ch2/ch2_max);
	
	    double* norm_fac = (double*)calloc(num_edges-1, sizeof(double)); //normalization factor 1

		for (int j = 0; j < (num_edges-1); j++) {
				lags[j] = lag_bin_edges[j] + (lag_bin_edges[j+1] - lag_bin_edges[j]) / 2;
			
				if (ch1_max < ch2_max-lags[j])
					norm_fac[j] = ch1_max;
				else
				    norm_fac[j] = ch2_max-lags[j];

		} 
	
	    double* division_factor = (double*)calloc(num_edges, sizeof(double)); //division factor for log spaced bins

		double multiplier = 0;
		int n = (int) coarseness;
		for (int j = 0; j < (int) cascade_end; j++) {
			for (int k = 0; k < n; k++) {
				multiplier = pow(2,j+1);
				division_factor[j*n + k] = multiplier;
			}
		}

		for (int j = 0; j< (num_edges-1); j++){
			curr_acf = acf[j];
			acf[j] = 2*curr_acf/division_factor[j+1]/norm_fac[j]/ch1_ch2_ratio;
		}
	
	
		acf_bounds[0] = (int)(cascade_start*coarseness);
		acf_bounds[1] = num_edges-1;
	

	    free(lag_bin_edges);
		free(low_inds);
		free(max_inds);
		free(bin_edges);
	    free(division_factor);
		free(norm_fac);
	}
}

void picoquant_g2_corr(double *ch1, double* ch2, int num_ch1, int num_ch2, double ps_range, 
							   int num_edges, double offset_lag_ps, double *acf, double *lags){
								   
	if ((num_ch1 > 0) && (num_ch2 > 0))
	{ 
		
		double* lag_bin_edges = (double*)calloc(num_edges, sizeof(double)); //array for lag bins
		double dbin = ps_range/num_edges;
		int num_negative_bins = (int) floor(num_edges/2);
		
		for (int bin_ind = 0; bin_ind < num_edges; bin_ind++){
			double curr_bin = (double) bin_ind - num_negative_bins;
			lag_bin_edges[bin_ind] = dbin*curr_bin;
			lags[bin_ind] = dbin*curr_bin;
		}
	
		int* low_inds = (int*)calloc(num_edges, sizeof(int)); //index of the earlies photon in each bin
		int* max_inds = (int*)calloc(num_edges, sizeof(int)); //index of the last photon in each bin
		double* bin_edges = (double*)calloc(num_edges, sizeof(double));
	
	    int curr_low, curr_max;
		double curr_acf;
	
	//for each photon in ch1
		for (int phot_ind = 0; phot_ind < num_ch1; phot_ind++) {

			//shift the lags for each photon
			for (int edge_ind = 0; edge_ind < num_edges; edge_ind++) {
				bin_edges[edge_ind] = ch1[phot_ind] + lag_bin_edges[edge_ind] + offset_lag_ps;
			}

			for (int k = 0; k < (num_edges - 1); k++) {

				curr_low = low_inds[k];
				while (low_inds[k] < num_ch2 && ch2[curr_low] < bin_edges[k]) {
					low_inds[k] = curr_low + 1;
					curr_low = low_inds[k];
				}

				curr_max = max_inds[k];
				while (max_inds[k] < num_ch2 && ch2[curr_max] <= bin_edges[k + 1]) {
					max_inds[k] = curr_max + 1;
					curr_max = max_inds[k];
				}

				low_inds[k + 1] = max_inds[k];
				curr_acf = acf[k];
				acf[k] = curr_acf + (max_inds[k] - low_inds[k]);

			}
		}
	
	
	    free(lag_bin_edges);
		free(low_inds);
		free(max_inds);
		free(bin_edges);
	}

								   
}
