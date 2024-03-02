import React, { useState, useEffect, Fragment } from "react";
import {
  Button,
  Grid,
  Header,
  Label,
  Accordion,
  Divider,
  Form,
  Breadcrumb,
  Table,
  Tab,
} from "semantic-ui-react";
import _ from "lodash";

import "semantic-ui-css/semantic.min.css";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import MessageBox from "../Shared/MessageBox";
import moment from "moment";
import axios from "axios";
import { DateInput } from "semantic-ui-calendar-react";
import { tableSortReducer } from "../Shared/TableSort";

export default function EawsUsageReport({
  projects,
  services,
  date_to,
  date_from,
  token,
}) {
  const [message, setMessage] = useState(null);
  const [accordionState, setAccordionState] = useState(false);
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [data, setData] = useState({
    image_requests: [],
    top_20_users: [],
    unique_users: [],
  });

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  // console.log("EsriLogExport", {
  //   projects,
  //   services,
  //   date_to,
  //   date_from,
  //   token,
  //   data,
  // });

  // Testing
  // useEffect(() => {
  //   onSubmit({ project: "SL", date_from: "01/01/2022", date_to: "07/01/2022" });
  // }, []);

  const resetForm = () => {
    reset({
      project: "",
      date_from: date_from,
      date_to: date_to,
    });
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const onSubmit = (data) => {
    console.error("onSubmit", data);
    setLoading(true)
    setSubmitted(true)
    axios
      .post(`/eaws_usage_report`, {
        authenticity_token: token,
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("submit response", data);
        setLoading(false)
        setSubmitted(false)
        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });
        // Reset form if successful
        if (data.state) {
          setData({
            image_requests: data.result.image_requests,
            top_20_users: data.result.top_20_users,
            unique_users: data.result.unique_users,
          });

          // setTimeout(() => {
          //   resetForm();
          // }, 500);
        } else {
          setData({
            image_requests: [],
            top_20_users: [],
            unique_users: [],
          });
        }
        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  const onExport = (data) => {
    console.error("onExport", data);

    axios
      .post(`/eaws_usage_export`, {
        authenticity_token: token,
        project: data.project,
        date_from: moment(data.date_from, "l").format("YYYY-MM-DD"),
        date_to: moment(data.date_to, "l").format("YYYY-MM-DD"),
      })
      .then(({ data }) => {
        console.log("Export response", data);
        // Set message
        // setMessage({
        //   status: data.state ? "Success" : "Error",
        //   text: data.message,
        // });
        // // Reset form if successful
        // if (data.state) {
        //   setData({
        //     image_requests: data.result.image_requests,
        //     top_20_users: data.result.top_20_users,
        //     unique_users: data.result.unique_users,
        //   });

        //   // setTimeout(() => {
        //   //   resetForm();
        //   // }, 500);
        // } else {
        //   setData(null);
        // }
        if (data.history_id) {
          window.open(`/eaws_usage_download/${data.history_id}`, "_blank");
        }

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Reports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section active>EAWS Usage</Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />
      {/* {renderHelp()} */}
      {/* <Divider /> */}
      {renderMessage()}
      {renderForm()}
      {renderTabs()}
      <br />
      <br />
    </div>
  );

  //   function renderHelp() {
  //     return (
  //       <Accordion styled fluid>
  //         <Accordion.Title
  //           active={accordionState}
  //           onClick={() => {
  //             setAccordionState(!accordionState);
  //           }}
  //         >
  //           <Icon name="dropdown" />
  //           Tool Help
  //         </Accordion.Title>
  //         <Accordion.Content active={accordionState}>
  //           <Header as="h4">Summary</Header>
  //           <p>Imports the DOQQs via Shapefile</p>
  //           <Divider />
  //           <Grid divided="vertically">
  //             <Grid.Row columns={2}>
  //               <Grid.Column>
  //                 <Header as="h5">Inputs</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     A <b>single shapefile</b> that contains a{" "}
  //                     <b>.shp, .shx, .dbf, and .prj</b> files
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //               <Grid.Column>
  //                 <Header as="h5">Process</Header>
  //                 <List bulleted>
  //                   <List.Item>
  //                     The associationed County, State, and UTM will be verified
  //                     and calculated
  //                   </List.Item>
  //                 </List>
  //               </Grid.Column>
  //             </Grid.Row>
  //           </Grid>
  //         </Accordion.Content>
  //       </Accordion>
  //     );
  //   }

  function renderMessage() {
    if (!message) return null;
    return (
      <MessageBox
        status={message.status}
        title={message.title}
        message={message.text}
      />
    );
  }

  function renderForm() {
    if (message && message.status === "loading") return null;

    return (
      <Form>
        <Form.Group widths="equal">
          <Controller
            name={"project"}
            control={control}
            rules={{ required: "Required" }}
            render={({ field: { name, value } }) => (
              <Form.Select
                fluid
                search
                selection
                clearable
                name={name}
                data-value={value}
                label={"Project"}
                required={true}
                value={value}
                onChange={handleChange}
                autoComplete="off"
                options={projects.map((record) => {
                  return {
                    key: record,
                    text: record,
                    value: record,
                  };
                })}
                error={
                  errors["project"]
                    ? {
                        content: errors["project"].message,
                        pointing: "above",
                      }
                    : false
                }
              />
            )}
          />
          <Form.Field error={errors.hasOwnProperty("date_from")}>
            <div className="calendar-input">
              <Controller
                name={"date_from"}
                control={control}
                rules={{
                  required: "Required",
                }}
                defaultValue={date_from}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Date From"}
                    required={true}
                    value={value || ""}
                    dateFormat="MM/DD/YYYY"
                    iconPosition="left"
                    onChange={handleChange}
                    autoComplete="off"
                  />
                )}
              />
            </div>
            {errors[`date_from`] && (
              <Label pointing prompt>
                {errors[`date_from`].message}
              </Label>
            )}
          </Form.Field>
          <Form.Field error={errors.hasOwnProperty("date_to")}>
            <div className="calendar-input">
              <Controller
                name={"date_to"}
                control={control}
                rules={{
                  required: "Required",
                }}
                defaultValue={date_to}
                render={({ field: { name, value } }) => (
                  <DateInput
                    closable
                    clearable
                    name={name}
                    label={"Date To"}
                    required={true}
                    value={value || ""}
                    dateFormat="MM/DD/YYYY"
                    iconPosition="left"
                    onChange={handleChange}
                    autoComplete="off"
                  />
                )}
              />
            </div>
            {errors[`date_to`] && (
              <Label pointing prompt>
                {errors[`date_to`].message}
              </Label>
            )}
          </Form.Field>
        </Form.Group>
        <Divider />
        <Button.Group floated="right">
          <Button primary onClick={handleSubmit(onSubmit)}>
            Submit
          </Button>
          <Button.Or />
          <Button onClick={handleSubmit(onExport)}>Export</Button>
        </Button.Group>
        {/* <Button
          primary
          floated="right"
          type="button"
          onClick={handleSubmit(onExport)}
        >
          Export
        </Button>
        <Button
          primary
          floated="right"
          type="button"
          onClick={handleSubmit(onSubmit)}
        >
          Submit
        </Button> */}
        <Button
          secondary
          floated="right"
          type="button"
          style={{ marginRight: "0.5em" }}
          loading={submitted}
          disabled={submitted}
          onClick={() => resetForm()}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
      </Form>
    );
  }

  function renderTabs() {
    if (
      data.image_requests.length === 0 &&
      data.top_20_users.length === 0 &&
      data.unique_users.length === 0
    )
      return null;

    return (
      <Fragment>
        <Divider />
        <Tab
          menu={{ secondary: true, pointing: true }}
          panes={[
            {
              menuItem: "Unique Uses per Week",
              render: () => <UniqueUsesPerWeek records={data.unique_users} />,
            },
            {
              menuItem: "Image Requests",
              render: () => <ImageRequests records={data.image_requests} />,
            },
            {
              menuItem: "Top 20 Users",
              render: () => <Top20Users records={data.top_20_users} />,
            },
          ]}
        />
      </Fragment>
    );
  }

  function RenderLoading() {
    return (
      <MessageBox
        status={"loading"}
        title={"Loading"}
        message={"Building Table..."}
      />
    );
  }

  function UniqueUsesPerWeek({ records }) {
    if (!records) return <RenderLoading />;

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    console.log("UniqueUsesPerWeek", { data });

    if (records.length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Table sortable celled>
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "service" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "service" })
              }
            >
              Service
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "ip_address" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "ip_address" })
              }
            >
              IP Address
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "domain" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "domain" })
              }
            >
              Domain
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "count" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "count" })}
            >
              Count
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.service}</Table.Cell>
                <Table.Cell>{record.ip_address}</Table.Cell>
                <Table.Cell>{record.domain}</Table.Cell>
                <Table.Cell>{record.count}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }

  function ImageRequests({ records }) {
    if (!records) return <RenderLoading />;

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    console.log("ImageRequests", { data });

    if (records.length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Table sortable celled>
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "service" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "service" })
              }
            >
              Service
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "count" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "count" })}
            >
              Count
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.service}</Table.Cell>
                <Table.Cell>{record.count}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }

  function Top20Users({ records }) {
    if (!records) return <RenderLoading />;

    const [state, dispatch] = React.useReducer(tableSortReducer, {
      column: null,
      data: records,
      direction: null,
    });
    const { column, data, direction } = state;

    console.log("Top20Users", { data });

    if (records.length === 0) {
      return (
        <MessageBox
          title={"No Records Found"}
          message={"Query returned no records"}
        />
      );
    }

    return (
      <Table sortable celled>
        <Table.Header>
          <Table.Row>
            <Table.HeaderCell
              sorted={column === "project" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "project" })
              }
            >
              Project
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "ip_address" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "ip_address" })
              }
            >
              IP Address
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "domain" ? direction : null}
              onClick={() =>
                dispatch({ type: "CHANGE_SORT", column: "domain" })
              }
            >
              Domain
            </Table.HeaderCell>
            <Table.HeaderCell
              sorted={column === "count" ? direction : null}
              onClick={() => dispatch({ type: "CHANGE_SORT", column: "count" })}
            >
              Count
            </Table.HeaderCell>
          </Table.Row>
        </Table.Header>

        <Table.Body>
          {data.map((record, index) => {
            return (
              <Table.Row key={index}>
                <Table.Cell>{record.project}</Table.Cell>
                <Table.Cell>{record.ip_address}</Table.Cell>
                <Table.Cell>{record.domain}</Table.Cell>
                <Table.Cell>{record.count}</Table.Cell>
              </Table.Row>
            );
          })}
        </Table.Body>
      </Table>
    );
  }
}
