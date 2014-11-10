/*****************************
// NDPRead.h - NDP data access library
// (c) Copyright 2011 Hamamatsu Photonics K.K.
// Version 1.1.32
//***************************/



#define NDPREAD_CHANNELORDER_UNDEFINED	(0)
#define NDPREAD_CHANNELORDER_BGR		(1)
#define NDPREAD_CHANNELORDER_RGB		(2)
#define NDPREAD_CHANNELORDER_Y			(3)


#ifdef _UNICODE

#define	GetImageWidth					GetImageWidthW
#define	GetImageHeight					GetImageHeightW
#define	GetImageBitDepth				GetImageBitDepthW
#define	GetNoChannels					GetNoChannelsW
#define GetChannelOrder					GetChannelOrderW
#define	GetImageData					GetImageDataW
#define	GetImageDataEx					GetImageDataExW
#define	GetImageData16					GetImageData16W
#define GetImageDataInSourceBitDepth	GetImageDataInSourceBitDepthW
#define GetImageDataInSourceBitDepthEx	GetImageDataInSourceBitDepthExW
#define	GetSourceLens					GetSourceLensW
#define	GetSourcePixelSize				GetSourcePixelSizeW
#define	GetReference					GetReferenceW
#define	GetMap							GetMapW
#define	GetMapEx						GetMapExW
#define	GetSlideImage					GetSlideImageW
#define	GetZRange						GetZRangeW
#define	GetLastErrorMessage				GetLastErrorMessageW
#define	GetLowLevelParam				GetLowLevelParamW
#define	SetLowLevelParam				SetLowLevelParamW

#endif //#ifdef _UNICODE

//#ifdef __cplusplus
//extern "C"
//{
	typedef struct
	{
		unsigned long	nSize;	/* Set to sizeof(GetImageDataExParams) */
		long			nPhysicalXPos;
		long			nPhysicalYPos;
		long			nPhysicalZPos;
		float			fMag;
		long			nPixelWidth;
		long			nPixelHeight;
		long			nPhysicalWidth;
		long			nPhysicalHeight;
		void		   *pBuffer;
		long			nBufferSize;
	} GetImageDataExParams;
	
	typedef struct
	{
		unsigned long	nSize;	/* Set to sizeof(GetMapExParams) */
		long			nPixelWidth;
		long			nPixelHeight;
		long			nPhysicalX;
		long			nPhysicalY;
		long			nPhysicalWidth;
		long			nPhysicalHeight;
		void		   *pBuffer;
		long			nBufferSize;
	} GetMapExParams;
	
#ifdef _UNICODE
	
	long	GetImageWidthW(char* i_strImageID);
	long	GetImageHeightW(char* i_strImageID);
	long	GetImageBitDepthW(char* i_strImageID);
	long	GetNoChannelsW(char* i_strImageID);
	long	GetChannelOrder(char* i_strImageID);
	long	GetImageDataW(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataExW(char* i_strImageID, GetImageDataExParams *i_pParams);
	long	GetImageData16W(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataInSourceBitDepthW(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataInSourceBitDepthExW(char* i_strImageID, GetImageDataExParams *i_pParams);
	float	GetSourceLensW(char* i_strImageID);
	long	GetSourcePixelSizeW(char* i_strImageID, long *o_nWidth, long *o_nHeight);
	long	GetReferenceW(char* i_strImageID, LPWSTR o_strReference, long i_nBufferLength);
	long	GetMapW(char* i_strImageID, long *o_nPhysicalX, long *o_nPhysicalY, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize, long *o_nPixelWidth, long *o_nPixelHeight);
	long	GetMapExW(char* i_strImageID, GetMapExParams *i_pParams);
	long	GetSlideImageW(char* i_strImageID, long *o_nPhysicalX, long *o_nPhysicalY, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize, long *o_nPixelWidth, long *o_nPixelHeight);
	long	GetZRangeW(char* i_strImageID, long *o_nMin, long *o_nMax, long *o_nStep);
	char*	GetLastErrorMessageW();
	long	GetLowLevelParamW(char* i_strImageID, char* i_strParamID, LPWSTR o_strValue, long i_nBufferLength);
	long	SetLowLevelParamW(char* i_strImageID, char* i_strParamID, char* i_strParamValue);
	
#else
	
	long	GetImageWidth(char* i_strImageID);
	long	GetImageHeight(char* i_strImageID);
	long	GetImageBitDepth(char* i_strImageID);
	long	GetNoChannels(char* i_strImageID);
	long	GetChannelOrder(char* i_strImageID);
	long	GetMap(char* i_strImageID, long *o_nPhysicalX, long *o_nPhysicalY, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize, long *o_nPixelWidth, long *o_nPixelHeight);
	long	GetMapEx(char* i_strImageID, GetMapExParams *i_pParams);
	long	GetSlideImage(char* i_strImageID, long *o_nPhysicalX, long *o_nPhysicalY, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize, long *o_nPixelWidth, long *o_nPixelHeight);
	long	GetZRange(char* i_strImageID, long *o_nMin, long *o_nMax, long *o_nStep);
	long	GetImageData(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataEx(char* i_strImageID, GetImageDataExParams *i_pParams);
	long	GetImageData16(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataInSourceBitDepth(char* i_strImageID, long i_nPhysicalXPos, long i_nPhysicalYPos, long i_nPhysicalZPos, float i_fMag, long *o_nPhysicalWidth, long *o_nPhysicalHeight, void *i_pBuffer, long *io_nBufferSize);
	long	GetImageDataInSourceBitDepthEx(char* i_strImageID, GetImageDataExParams *i_pParams);
	float	GetSourceLens(char* i_strImageID);
	long	GetSourcePixelSize(char* i_strImageID, long *o_nWidth, long *o_nHeight);
	long	GetReference(char* i_strImageID, char* o_strReference, long i_nBufferLength);
	char*	GetLastErrorMessage();
	long	GetLowLevelParam(char* i_strImageID, char* i_strParamID, char* o_strValue, long i_nBufferLength);
	long	SetLowLevelParam(char* i_strImageID, char* i_strParamID, char* i_strParamValue);
	
#endif //#ifdef _UNICODE
	
	long	SetCameraResolution(long i_nWidth, long i_nHeight);
	long	CleanUp();
	long	SetOption(long i_nOptionID, long i_nOptionValue);
//}
//#endif
