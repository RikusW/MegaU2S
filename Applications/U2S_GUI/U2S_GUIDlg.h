// U2S_GUIDlg.h : header file
//

#if !defined(AFX_U2S_GUIDLG_H__7A540341_C2A5_4890_98F4_882354EB2F32__INCLUDED_)
#define AFX_U2S_GUIDLG_H__7A540341_C2A5_4890_98F4_882354EB2F32__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

/////////////////////////////////////////////////////////////////////////////
// CU2S_GUIDlg dialog

class CU2S_GUIDlg : public CDialog
{
// Construction
public:
	CU2S_GUIDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CU2S_GUIDlg)
	enum { IDD = IDD_U2S_GUI_DIALOG };
	CComboBox	m_ComPort;
	CString	m_Partid;
	CString	m_Serial;
	int		m_Version;
	CString	m_AppSize;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CU2S_GUIDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;
	unsigned short m_Address;

	bool Connect(BYTE m);
	void Disconnect();
	bool SelectMode(BYTE);

	// Generated message map functions
	//{{AFX_MSG(CU2S_GUIDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnSetToBL();
	afx_msg void OnSetToApp();
	afx_msg void OnSetToDebug();
	afx_msg void OnUpdateInfo();
	afx_msg void OnSelchangeCombo1();
	afx_msg void OnSetToJTAG();
	afx_msg void OnModUnlock();
	afx_msg void OnSetToSTK500();
	afx_msg void OnSetToUART();
	afx_msg void OnSetToDW();
	afx_msg void OnButtonSettings();
	afx_msg void OnButton12();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_U2S_GUIDLG_H__7A540341_C2A5_4890_98F4_882354EB2F32__INCLUDED_)
