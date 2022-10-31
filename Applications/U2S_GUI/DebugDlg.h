#if !defined(AFX_DEBUGDLG_H__7F34FEAF_BC38_4934_A021_ED6E0F181944__INCLUDED_)
#define AFX_DEBUGDLG_H__7F34FEAF_BC38_4934_A021_ED6E0F181944__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000
// DebugDlg.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// DebugDlg dialog

class DebugDlg : public CDialog
{
// Construction
public:
	DebugDlg(CWnd* pParent = NULL);   // standard constructor

// Dialog Data
	//{{AFX_DATA(DebugDlg)
	enum { IDD = IDD_DIALOG_DEBUG };
		// NOTE: the ClassWizard will add data members here
	//}}AFX_DATA


// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(DebugDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

	int X,Y;
	void Highlight(int,int);
	void DRect(CDC *dc, COLORREF c, int x, int y);

// Implementation
protected:

	// Generated message map functions
	//{{AFX_MSG(DebugDlg)
	afx_msg void OnPaint();
	afx_msg void OnMouseMove(UINT nFlags, CPoint point);
	virtual BOOL OnInitDialog();
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	afx_msg void OnTimer(UINT nIDEvent);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_DEBUGDLG_H__7F34FEAF_BC38_4934_A021_ED6E0F181944__INCLUDED_)
