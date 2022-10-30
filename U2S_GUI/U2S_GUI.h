// U2S_GUI.h : main header file for the U2S_GUI application
//

#if !defined(AFX_U2S_GUI_H__A85B20DB_9577_4C2C_98A4_7DD7A9133E80__INCLUDED_)
#define AFX_U2S_GUI_H__A85B20DB_9577_4C2C_98A4_7DD7A9133E80__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CU2S_GUIApp:
// See U2S_GUI.cpp for the implementation of this class
//

class CU2S_GUIApp : public CWinApp
{
public:
	CU2S_GUIApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CU2S_GUIApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CU2S_GUIApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_U2S_GUI_H__A85B20DB_9577_4C2C_98A4_7DD7A9133E80__INCLUDED_)
