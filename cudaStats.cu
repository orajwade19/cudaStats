#include<iostream>
#include<stdio.h>
#include<stdlib.h>
#include<math.h>
#define THREADS_PER_BLOCK 1024
using namespace std;

__global__ void subAvg(int* input,int count,int avg)
{
	int index = blockDim.x*blockIdx.x + threadIdx.x;
	if(index<count)
	input[index] = pow(input[index]-avg,2);
}

__global__ void max(int* input,int count)
{
	int blockStartPoint = blockDim.x*blockIdx.x;
	int threadWithinBlock = threadIdx.x;
	int scopeSize = 1;
	while(scopeSize<=THREADS_PER_BLOCK)
	{
		int threadLimit = THREADS_PER_BLOCK/scopeSize;
		if(threadWithinBlock<threadLimit)
		{
			int first = blockStartPoint*2 + threadWithinBlock*scopeSize*2;
			int second = first + scopeSize;
			if(first<count && second<count)
			{
				if(input[second]>input[first])
				input[first] = input[second];
			}
		}
		__syncthreads();
		scopeSize*=2;		
	}

}
__global__ void maxFinalize(int* input,int count)
{
	int maximum = input[0];
	for(int i=2048;i<count;i+=2048)
	{
		if(input[i]>maximum)
		maximum = input[i];
	}
	input[0] = maximum;
}

__global__ void min(int* input,int count)
{
	int blockStartPoint = blockDim.x*blockIdx.x;
	int threadWithinBlock = threadIdx.x;
	int scopeSize = 1;
	while(scopeSize<=THREADS_PER_BLOCK)
	{
		int threadLimit = THREADS_PER_BLOCK/scopeSize;
		if(threadWithinBlock<threadLimit)
		{
			int first = blockStartPoint*2 + threadWithinBlock*scopeSize*2;
			int second = first + scopeSize;
			if(first<count && second<count)
			{
				if(input[second]<input[first])
				input[first] = input[second];
			}
		}
		__syncthreads();
		scopeSize*=2;		
	}

}
__global__ void minFinalize(int* input,int count)
{
	int minimum = input[0];
	for(int i=2048;i<count;i+=2048)
	{
		if(input[i]<minimum)
		minimum = input[i];
	}
	input[0] = minimum;
}

__global__ void sum(int* input,int count)
{
	int blockStartPoint = blockDim.x*blockIdx.x;
	int threadWithinBlock = threadIdx.x;
	int scopeSize = 1;
	while(scopeSize<=THREADS_PER_BLOCK)
	{
		int threadLimit = THREADS_PER_BLOCK/scopeSize;
		if(threadWithinBlock<threadLimit)
		{
			int first = blockStartPoint*2 + threadWithinBlock*scopeSize*2;
			int second = first + scopeSize;
			if(first<count && second<count)
			{
				input[first] += input[second];
			}
		}
		__syncthreads();
		scopeSize*=2;		
	}

}

__global__ void sum2(int* input,int count)
{
	int blockStartPoint = blockDim.x*blockIdx.x;
	int threadWithinBlock = threadIdx.x;
	int scopeSize = 1;
	while(scopeSize<=THREADS_PER_BLOCK)
	{
		int threadLimit = THREADS_PER_BLOCK/scopeSize;
		if(threadWithinBlock<threadLimit)
		{
			int first = blockStartPoint*2 + threadWithinBlock*scopeSize*2;
			int second = first + scopeSize;
			if(first<count && second<count)
			{
				input[first] += input[second];
			}
		}
		__syncthreads();
		scopeSize*=2;		
	}

}
__global__ void sumUp(int* input,int count)
{
	for(int i=2048;i<count;i+=2048)
	{
		input[0] += input[i];
	}
}

int main(int argc, char const *argv[])
{	
	srand(3);
	//common part
	int count = 0;
	cout<<"Enter the number of elements:";
	cin>>count;
	int size = count * sizeof(int);
	int h[count];	     //allocating host memory
	int *d;
	cudaMalloc(&d,size); //allocating device memory
	int blockSize = 1024;//initializing the max block size
	float numBlocks = floor((count+blockSize-1)/blockSize);
	numBlocks = ceil(numBlocks/2);//calculating number of blocks

	cout<<"Elements are:"<<endl;
	for (int i = 0; i < count; i++)
	{
		h[i] = i + 1;
		cout<<h[i]<<"\t";
	}
	
	//calculating minimum
	cudaMemcpy(d,h,size,cudaMemcpyHostToDevice);
	min<<<numBlocks,blockSize>>> (d,count);
	minFinalize<<<1,1>>> (d,count);
	int result;
	cudaMemcpy(&result,d,sizeof(int),cudaMemcpyDeviceToHost);
	cout<<"Minimum Element:"<<result<<endl;

	//calculating maximum
	cudaMemcpy(d,h,size,cudaMemcpyHostToDevice);
	max<<<numBlocks,blockSize>>> (d,count);
	maxFinalize<<<1,1>>> (d,count);
	cudaMemcpy(&result,d,sizeof(int),cudaMemcpyDeviceToHost);
	cout<<"Maximum Element:"<<result<<endl;

	//calculating sum
	cudaMemcpy(d,h,size,cudaMemcpyHostToDevice);
	sum<<<numBlocks,blockSize>>> (d,count);
	sumUp<<<1,1>>> (d,count);
	cudaMemcpy(&result,d,sizeof(int),cudaMemcpyDeviceToHost);
	cout<<"Sum is "<<result<<endl;
	cout<<"Correct sum(by formula)*ONLY IF INPUT IS 1...n* is:"<<count*(2+(count-1))/2<<endl;
	int sum = result;
	int average = sum/count;
	cout<<"Average is:"<<average<<endl;
	//calculating variance and standard deviation
	cudaMemcpy(d,h,size,cudaMemcpyHostToDevice);
	int subAvgnumBlocks = (count+blockSize-1)/blockSize;
	subAvg<<<subAvgnumBlocks,blockSize>>>(d,count,average);
	sum2<<<numBlocks,blockSize>>> (d,count);
	sumUp<<<1,1>>>(d,count);
	cudaMemcpy(&result,d,sizeof(int),cudaMemcpyDeviceToHost);
	cout<<"Variance is "<<result<<endl;
	cout<<"Standard Deviation is "<<sqrt(result)<<endl;




	getchar();
	cudaFree(d);

	return 0;
}
